resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "allow inbound to ecs from alb"
  vpc_id      = aws_vpc.main.id # Replace with your VPC ID

  #   ingress {
  #     description     = "Allow app servers to connect"
  #     from_port       = 5432
  #     to_port         = 5432
  #     protocol        = "tcp"
  #     security_groups = ["sg-0123456789abcdef0"] # Replace with your Application/EC2 Security Group ID
  #   }
}