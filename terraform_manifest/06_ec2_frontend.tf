# # Public EC2 Instance
# resource "aws_security_group" "public_ec2_ssh" {
#   name        = "public_ec2_ssh"
#   description = "Allow SSH and HTTP access"

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   vpc_id = aws_vpc.POC-01.id
# }

# resource "aws_instance" "public_instance" {
#   ami                    = "ami-0b09627181c8d5778"
#   instance_type          = "t2.micro"
#   key_name               = "temp-key"
#   subnet_id              = aws_subnet.Public-subnet-1.id
#   vpc_security_group_ids = [aws_security_group.public_ec2_ssh.id]
#   user_data = templatefile("${path.module}/user_data.sh", {
#     api_url = aws_apigatewayv2_api.api.api_endpoint
#   })
# }

# output "public_ip_ec2" {
#   value = aws_instance.public_instance.public_ip
# }