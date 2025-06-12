## vpc
resource "aws_vpc" "POC-01" {
  cidr_block       = "11.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "POC-01"
  }
}
## Subnets
resource "aws_subnet" "Public-subnet-1" {
  vpc_id                  = aws_vpc.POC-01.id
  availability_zone       = "ap-south-1a"
  cidr_block              = "11.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-subnet-1"
  }
}
resource "aws_subnet" "Public-subnet-2" {
  vpc_id            = aws_vpc.POC-01.id
  availability_zone = "ap-south-1b"
  cidr_block        = "11.0.3.0/24"

  tags = {
    Name = "Public-subnet-2"
  }
}
resource "aws_subnet" "Private-subnet-1" {
  vpc_id            = aws_vpc.POC-01.id
  availability_zone = "ap-south-1a"
  cidr_block        = "11.0.2.0/24"

  tags = {
    Name = "Private-subnet-1"
  }
}
resource "aws_subnet" "Private-subnet-2" {
  vpc_id            = aws_vpc.POC-01.id
  availability_zone = "ap-south-1b"
  cidr_block        = "11.0.4.0/24"

  tags = {
    Name = "Private-subnet-2"
  }
}

## Internet Gateway
resource "aws_internet_gateway" "POC-01" {
  vpc_id = aws_vpc.POC-01.id

  tags = {
    Name = "POC-01"
  }
}

## Nat Gateway
resource "aws_eip" "POC-01" {

  tags = {
    Name = "gw NAT EIP"
  }
}
resource "aws_nat_gateway" "POC-01" {
  allocation_id = aws_eip.POC-01.id
  subnet_id     = aws_subnet.Public-subnet-1.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.POC-01]
}

## Route Table
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.POC-01.id

  route {
    cidr_block = "11.0.0.0/16"
    gateway_id = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.POC-01.id
  }
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.POC-01.id

  route {
    cidr_block = "11.0.0.0/16"
    gateway_id = "local"
  }
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.POC-01.id
  }
  tags = {
    Name = "private-route-table"
  }
}

# Route Table Association
resource "aws_route_table_association" "Public-a" {
  subnet_id      = aws_subnet.Public-subnet-1.id
  route_table_id = aws_route_table.public-route-table.id
}
resource "aws_route_table_association" "Public-b" {
  subnet_id      = aws_subnet.Public-subnet-2.id
  route_table_id = aws_route_table.public-route-table.id
}
resource "aws_route_table_association" "Private-a" {
  subnet_id      = aws_subnet.Private-subnet-1.id
  route_table_id = aws_route_table.private-route-table.id
}
resource "aws_route_table_association" "Private-b" {
  subnet_id      = aws_subnet.Private-subnet-2.id
  route_table_id = aws_route_table.private-route-table.id
}