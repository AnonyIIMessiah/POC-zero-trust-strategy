## vpc
resource "aws_vpc" "main" {
  cidr_block       = "11.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}
## Subnets
resource "aws_subnet" "Public-subnet-main-1" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "ap-south-1a"
  cidr_block              = "11.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-subnet-main-1"
  }
}
resource "aws_subnet" "Public-subnet-main-2" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-south-1b"
  cidr_block        = "11.0.3.0/24"

  tags = {
    Name = "Public-subnet-main-2"
  }
}
resource "aws_subnet" "Private-subnet-main-1" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-south-1a"
  cidr_block        = "11.0.2.0/24"

  tags = {
    Name = "Private-subnet-main-1"
  }
}
resource "aws_subnet" "Private-subnet-main-2" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-south-1b"
  cidr_block        = "11.0.4.0/24"

  tags = {
    Name = "Private-subnet-main-2"
  }
}

## Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

## Nat Gateway
resource "aws_eip" "main" {

  tags = {
    Name = "main gw NAT EIP"
  }
}
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.Public-subnet-main-1.id

  tags = {
    Name = "main gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}

## Route Table
resource "aws_route_table" "public-route-table-main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "11.0.0.0/16"
    gateway_id = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "public-route-table-main"
  }
}

resource "aws_route_table" "private-route-table-main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "11.0.0.0/16"
    gateway_id = "local"
  }
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = {
    Name = "private-route-table-main"
  }
}

# Route Table Association
resource "aws_route_table_association" "Public-a" {
  subnet_id      = aws_subnet.Public-subnet-main-1.id
  route_table_id = aws_route_table.public-route-table-main.id
}
resource "aws_route_table_association" "Public-b" {
  subnet_id      = aws_subnet.Public-subnet-main-2.id
  route_table_id = aws_route_table.public-route-table-main.id
}
resource "aws_route_table_association" "Private-a" {
  subnet_id      = aws_subnet.Private-subnet-main-1.id
  route_table_id = aws_route_table.private-route-table-main.id
}
resource "aws_route_table_association" "Private-b" {
  subnet_id      = aws_subnet.Private-subnet-main-2.id
  route_table_id = aws_route_table.private-route-table-main.id
}
