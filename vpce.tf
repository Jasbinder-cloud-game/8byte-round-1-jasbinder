data "aws_prefix_list" "s3" {
  name = "com.amazonaws.us-east-1.s3"
}

resource "aws_security_group" "ecr_endpoint_sg" {
  name        = "ecr-sg"
  description = "allow traffic from ecs tasks to ecr interface endpoints"
  vpc_id      = aws_vpc.main.id

  # ingress {
  #   description     = "https from ecs tasks"
  #   from_port       = 443
  #   to_port         = 443
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.ecs_sg.id]
  # }
}

resource "aws_vpc_security_group_ingress_rule" "example" {
  security_group_id = aws_security_group.ecr_endpoint_sg.id

  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
  referenced_security_group_id = aws_security_group.ecs_sg.id
}

resource "aws_vpc_endpoint" "ecr_auth_endpoint" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ecr_endpoint_sg.id,
  ]
  subnet_ids = [
    aws_subnet.app_pvt_subnet_1.id
  ]

  private_dns_enabled = true

  tags = {
    description = "Handles the registry authentication and image manifest pulls"
  }
}

resource "aws_vpc_endpoint" "ecr_api_endpoint" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.ecr_endpoint_sg.id,
  ]


  subnet_ids = [
    aws_subnet.app_pvt_subnet_2.id,
  ]

  private_dns_enabled = true

  tags = {
    description = "Handles API calls like ECS determining if the image exists or checking permissions"
  }
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.s3"
  route_table_ids = [
    aws_route_table.private_subnet_to_internet.id
  ]

  tags = {
    description = "Allows the ECS agent to download the heavy, actual container image layers stored by ECR"
  }
}

resource "aws_vpc_endpoint" "secrets_manager_endpoint" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.secretsmanager"
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.secrets_manager_vpce_sg.id,
  ]

  subnet_ids = [
    aws_subnet.app_pvt_subnet_1.id,
    aws_subnet.app_pvt_subnet_2.id,
  ]

  private_dns_enabled = true

  tags = {
    description = "Allows the ECS agent to retrieve secrets from AWS Secrets Manager"
  }
}

resource "aws_security_group" "secrets_manager_vpce_sg" {
  name        = "secrets-manager-vpce-sg"
  description = "allow traffic from ecs tasks to secrets manager interface endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "https from ecs tasks"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }
}