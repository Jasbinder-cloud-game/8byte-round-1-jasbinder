resource "aws_cloudwatch_log_group" "frontend_log_group" {
  name              = "/ecs/frontend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "backend_log_group" {
  name              = "/ecs/backend"
  retention_in_days = 7
}

# VPC Endpoint for ecs to connect to Cloudwatch to send logs
resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.cloudwatch_vpce_sg.id,
  ]
  subnet_ids = [
    aws_subnet.app_pvt_subnet_2.id,
  ]

  private_dns_enabled = true
}

# security group for the VPC endpoint to allows traffic (to send logs) from the ECS tasks to the CloudWatch endpoint
resource "aws_security_group" "cloudwatch_vpce_sg" {
  name        = "cloudwatch-vpce-sg"
  description = "allow traffic to send logs from ecs tasks to cloudwatch interface endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "https from ecs tasks"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }
}