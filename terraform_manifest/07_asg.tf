resource "aws_launch_template" "frontend" {
  name_prefix   = "frontend-"
  image_id      = "ami-0b09627181c8d5778"
  instance_type = "t2.small"
  key_name      = "POC"

  vpc_security_group_ids = [aws_security_group.private_ec2_sg.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    api_url                 = aws_apigatewayv2_api.api.api_endpoint,
    user_pool_id            = aws_cognito_user_pool.user_pool.id,
    user_pool_web_client_id = aws_cognito_user_pool_client.user_pool_client.id,
    app_auth_domain         = aws_cognito_user_pool_domain.user_pool_domain.domain,
    redirect_sign_in        = "https://${aws_lb.app_lb.dns_name}/callback",
    redirect_sign_out       = "https://${aws_lb.app_lb.dns_name}/logout"
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "frontend-instance"
    }
  }
}

# EC2 Security Group (allow traffic only from ALB)
resource "aws_security_group" "private_ec2_sg" {
  name        = "private_ec2_sg"
  description = "Allow traffic from ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["11.0.0.0/16", "12.0.0.0/16"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_autoscaling_group" "frontend_asg" {
  name                = "frontend-asg"
  desired_capacity    = 1
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.Private-subnet-main-1.id, aws_subnet.Private-subnet-main-2.id]
  target_group_arns   = [aws_lb_target_group.app_tg.arn]
  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "frontend-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

}