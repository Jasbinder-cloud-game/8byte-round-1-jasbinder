resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "allow traffic from alb to ecs"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "allow traffice from alb to ecs"
    from_port       = 5000
    to_port         = 5000
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
  egress {
    description     = "HTTPS out to Amazon S3 Gateway Endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_prefix_list.s3.id]
  }
}

resource "aws_security_group_rule" "allow_ecs_to_ecr" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecr_endpoint_sg.id # Where the rule is applied
  source_security_group_id = aws_security_group.ecs_sg.id          # The traffic source
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

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "my-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 512 MB
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "my-web-app"
    image     = "${aws_ecr_repository.artifactory.repository_url}:${var.docker_image_tag}"
    essential = true
    portMappings = [{
      containerPort = 5000
      hostPort      = 5000
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group  = aws_cloudwatch_log_group.ecs_logs.name
        awslogs-region = "us-east-1"
      }
    }
  }])
}

resource "aws_ecs_service" "app" {
  name            = "my-app-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "my-web-app"
    container_port   = 5000
  }

  network_configuration {
    subnets          = [aws_subnet.app_pvt_subnet_1.id, aws_subnet.app_pvt_subnet_2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
}


