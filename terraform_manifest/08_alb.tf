# WARNING: This uploads a self-signed certificate.
# This is NOT for production and WILL cause browser security warnings.
resource "aws_iam_server_certificate" "self_signed_cert" {
  name = "my-self-signed-cert"
  # The file() function reads the content from the generated files
  certificate_body = file("certificate.pem")
  private_key      = file("private-key.pem")

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Security Group (public access)
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.POC-01.id

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb" "app_lb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.Public-subnet-1.id, aws_subnet.Public-subnet-2.id]
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.POC-01.id

  # health_check {
  #   path                = "/"
  #   protocol            = "HTTP"
  #   interval            = 30
  #   timeout             = 5
  #   healthy_threshold   = 2
  #   unhealthy_threshold = 2
  # }
}
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 443
  protocol          = "HTTPS"
certificate_arn   = aws_iam_server_certificate.self_signed_cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.app_lb.dns_name
}
