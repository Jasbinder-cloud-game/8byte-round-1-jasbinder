resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "allow inbound to alb"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "allow traffice from internet to alb"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "internet_facing_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_2.id]

}

# target group  and listener for backend service
resource "aws_lb_target_group" "backend_service_target_group" {
  name        = "backend-tg"
  target_type = "ip"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id

  health_check {
    path     = "/health"
    port     = "traffic-port"
    protocol = "HTTP"
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.internet_facing_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_service_target_group.arn
  }
}

resource "aws_lb_listener_rule" "backend_listener_rule" {
  listener_arn = aws_lb_listener.app_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_service_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# target group and listener for frontend service

resource "aws_lb_target_group" "frontend_service_target_group" {
  name        = "frontend-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path     = "/health"
    port     = "traffic-port"
    protocol = "HTTP"
  }
}