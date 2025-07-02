# WARNING: This uploads a self-signed certificate.
# This is NOT for production and WILL cause browser security warnings.
resource "aws_iam_server_certificate" "self_signed_cert" {
  name             = "my-self-signed-cert"
  certificate_body = file("certificate.pem")
  private_key      = file("private-key.pem")

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Security Group 
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["12.0.0.0/16"]
  }
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["11.0.0.0/16", "12.0.0.0/16"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "50" # ESP
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ESP"
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
  subnets            = [aws_subnet.Public-subnet-main-1.id, aws_subnet.Public-subnet-main-2.id]
}

resource "aws_security_group_rule" "allow_https_from_windows" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["${aws_instance.windows_server.public_ip}/32"]
  description       = "Allow HTTPS traffic from Windows Server"
  security_group_id = aws_security_group.alb_sg.id
  depends_on        = [aws_instance.windows_server]
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
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
  value = "https://${aws_lb.app_lb.dns_name}"
}
