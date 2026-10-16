resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "allow traffic from alb to ecs"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "allow traffice from alb to ecs backend"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "allow traffice from alb to ecs frontend"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Outbound: Route ECR API & Auth traffic to the ECR interface endpoints
  # egress {
  #   description     = "HTTPS out to ECR interface endpoints"
  #   from_port       = 443
  #   to_port         = 443
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.ecr_endpoint_sg.id]
  # }

  # Outbound: Route heavy layer downloads to Amazon S3 via the Gateway Endpoint Prefix List
}

# egress rule to allow ECS tasks to send logs to CloudWatch via the VPC endpoint
resource "aws_vpc_security_group_egress_rule" "egress_rule_for_cloudwatch" {
  description                  = "ECS task egress to allow HTTPS to CloudWatch endpoints "
  security_group_id            = aws_security_group.ecs_sg.id
  referenced_security_group_id = aws_security_group.cloudwatch_vpce_sg.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}

# egress rule to allow ECS tasks to reach ECR vpce endpoint
resource "aws_vpc_security_group_egress_rule" "egress_rule_for_ecr" {
  description                  = "ECS task egress to allow HTTPS to ECR endpoints"
  security_group_id            = aws_security_group.ecs_sg.id
  referenced_security_group_id = aws_security_group.ecr_endpoint_sg.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}

# egress rule to allow ECS tasks to reach S3 vpce endpoint
resource "aws_vpc_security_group_egress_rule" "egress_rule_for_s3" {
  description       = "ECS task egress to allow HTTPS to S3 endpoints"
  security_group_id = aws_security_group.ecs_sg.id
  prefix_list_id    = data.aws_prefix_list.s3.id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "egress_rule_for_postgres" {
  description                  = "allow app to talk to rds"
  security_group_id            = aws_security_group.ecs_sg.id
  referenced_security_group_id = aws_security_group.postgres_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}
resource "aws_security_group_rule" "allow_ecs_to_ecr" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecr_endpoint_sg.id # Where the rule is applied
  source_security_group_id = aws_security_group.ecs_sg.id          # The traffic source
}

resource "aws_vpc_security_group_egress_rule" "egress_rule_for_secretsmanager" {
  description                  = "allow app to retireve secrets from secretsmanager"
  security_group_id            = aws_security_group.ecs_sg.id
  referenced_security_group_id = aws_security_group.secrets_manager_vpce_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "web-app-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Inline policy to allow reading secrets
resource "aws_iam_role_policy" "ecs_secrets_policy" {
  name = "ecs-secrets-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "${aws_db_instance.app_db.master_user_secret[0].secret_arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task definition and service for backend
resource "aws_ecs_task_definition" "backend_app" {
  family                   = "my-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 512 MB
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([{
    name      = "backend-container"
    image     = "${data.aws_ecr_repository.backend.repository_url}:${var.docker_image_tag}"
    essential = true
    environment = [
      { name = "DB_HOST", value = aws_db_instance.app_db.address },
      { name = "DB_PORT", value = tostring(aws_db_instance.app_db.port) },
      { name = "DB_NAME", value = aws_db_instance.app_db.db_name },
      { name = "DB_USER", value = aws_db_instance.app_db.username }
    ]
    secrets = [
      {
        name      = "DB_PASSWORD"
        valueFrom = "${aws_db_instance.app_db.master_user_secret[0].secret_arn}:password::"
      }
    ]
    portMappings = [{
      containerPort = 5000
      hostPort      = 5000
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group  = aws_cloudwatch_log_group.backend_log_group.name
        awslogs-region = "us-east-1"
      }
    }
  }])
}

resource "aws_ecs_service" "backend_app" {

  name            = "my-app-backend-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.backend_app.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  load_balancer {
    target_group_arn = aws_lb_target_group.backend_service_target_group.arn
    container_name   = "backend-container"
    container_port   = 5000
  }

  network_configuration {
    subnets          = [aws_subnet.app_pvt_subnet_1.id, aws_subnet.app_pvt_subnet_2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
  depends_on = [aws_iam_role.ecs_task_execution_role, aws_iam_role_policy.ecs_secrets_policy, aws_iam_role_policy_attachment.ecs_task_execution_policy]
}

# ECS Task definition and service for frontend

resource "aws_ecs_task_definition" "frontend_app" {
  family                   = "my-app-frontend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 512 MB
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }


  container_definitions = jsonencode([{
    name      = "frontend-container"
    image     = "${data.aws_ecr_repository.frontend.repository_url}:${var.docker_image_tag}"
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group  = aws_cloudwatch_log_group.frontend_log_group.name
        awslogs-region = "us-east-1"
      }
    }
  }])
}

resource "aws_ecs_service" "frontend_app_service" {
  name            = "my-app-frontend-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.frontend_app.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_service_target_group.arn
    container_name   = "frontend-container"
    container_port   = 80
  }

  network_configuration {
    subnets          = [aws_subnet.app_pvt_subnet_1.id, aws_subnet.app_pvt_subnet_2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
}
