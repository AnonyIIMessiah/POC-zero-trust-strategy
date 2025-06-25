variable "branch_office_name" {
  description = "Name of the branch office"
  type        = string
  default     = "branch-office-demo"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "12.0.0.0/16"
}

variable "allowed_ip_ranges" {
  description = "IP ranges allowed to access the branch office (your office/home IP)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Replace with your actual IP range
}

variable "instance_type" {
  description = "EC2 instance type for branch office workstations"
  type        = string
  default     = "t2.micro"
}



variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "BranchOfficePOC"
    Environment = "POC"
    Owner       = "DevOps"
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}


# VPC Configuration
resource "aws_vpc" "branch_office" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.branch_office_name}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "branch_office" {
  vpc_id = aws_vpc.branch_office.id

  tags = merge(var.tags, {
    Name = "${var.branch_office_name}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.branch_office.id
  cidr_block              = "12.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.branch_office_name}-public-${count.index + 1}"
    Type = "Public"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.branch_office.id
  cidr_block        = "12.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.branch_office_name}-private-${count.index + 1}"
    Type = "Private"
  })
}

# NAT Gateway for private subnet internet access
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.branch_office_name}-nat-eip"
  })
}

resource "aws_nat_gateway" "branch_office" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.tags, {
    Name = "${var.branch_office_name}-nat"
  })

  depends_on = [aws_internet_gateway.branch_office]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.branch_office.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.branch_office.id
  }

  tags = merge(var.tags, {
    Name = "${var.branch_office_name}-public-rt"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.branch_office.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.branch_office.id
  }

  tags = merge(var.tags, {
    Name = "${var.branch_office_name}-private-rt"
  })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "branch_office_server" {
  name        = "${var.branch_office_name}-server-sg"
  description = "Security group for branch office servers"
  vpc_id      = aws_vpc.branch_office.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "SSH from VPC"
  }
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH from VPC"
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "50" # ESP
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ESP"
  }

  # Example SG rule
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["11.0.0.0/16", "12.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.branch_office_name}-server-sg"
  })
}



# Linux Server
resource "aws_instance" "linux_server" {
  ami                    = "ami-0b09627181c8d5778"
  instance_type          = var.instance_type
  key_name               = "POC"
  vpc_security_group_ids = [aws_security_group.branch_office_server.id]
  subnet_id              = aws_subnet.private[0].id

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Branch Office Server - ${var.branch_office_name}</h1>" > /var/www/html/index.html
    echo "<p>Server is running successfully!</p>" >> /var/www/html/index.html
  EOF

  tags = merge(var.tags, {
    Name = "${var.branch_office_name}-linux-server"
    Type = "Server"
  })
}

# Application Load Balancer
resource "aws_lb" "branch_office" {
  name               = "${var.branch_office_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.branch_office_server.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "${var.branch_office_name}-alb"
  })
}

# Target Group
resource "aws_lb_target_group" "branch_office" {
  name     = "${var.branch_office_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.branch_office.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }

  tags = merge(var.tags, {
    Name = "${var.branch_office_name}-tg"
  })
}

# ALB Listener
resource "aws_lb_listener" "branch_office" {
  load_balancer_arn = aws_lb.branch_office.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.branch_office.arn
  }
}

# Target Group Attachment
resource "aws_lb_target_group_attachment" "branch_office" {
  target_group_arn = aws_lb_target_group.branch_office.arn
  target_id        = aws_instance.linux_server.id
  port             = 80
}

# S3 Bucket for branch office data
resource "aws_s3_bucket" "branch_office_data" {
  bucket        = "${var.branch_office_name}-data-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = merge(var.tags, {
    Name = "${var.branch_office_name}-data-bucket"
  })
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "branch_office_data" {
  bucket = aws_s3_bucket.branch_office_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "branch_office_data" {
  bucket = aws_s3_bucket.branch_office_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudWatch Log Group for monitoring
resource "aws_cloudwatch_log_group" "branch_office" {
  name              = "/aws/branch-office/${var.branch_office_name}"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.branch_office_name}-logs"
  })
}

# Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.branch_office.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}


output "linux_server_ip" {
  description = "Private IP of Linux server"
  value       = aws_instance.linux_server.private_ip
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.branch_office.dns_name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for branch office data"
  value       = aws_s3_bucket.branch_office_data.bucket
}

# Windows server
resource "aws_instance" "windows_server" {
  ami                    = "ami-036940a1a7418c22f"
  instance_type          = "t3.micro"
  key_name               = "POC"
  vpc_security_group_ids = [aws_security_group.branch_office_server.id]
  subnet_id              = aws_subnet.public[0].id

  tags = merge(var.tags, {
    Name = "${var.branch_office_name}-windows-server"
    Type = "Server"
  })
}
