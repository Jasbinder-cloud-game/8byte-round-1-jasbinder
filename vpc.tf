#VPC

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "my-project-vpc"
  }
}

#subnets - 2 private app, 2 db private and 2 public

resource "aws_subnet" "app_pvt_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "app-private-subnet-1"
  }
}

resource "aws_subnet" "app_pvt_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "app-private-subnet-2"
  }
}

resource "aws_subnet" "db_pvt_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "db-private-subnet-1"
  }
}

resource "aws_subnet" "db_pvt_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "db-private-subnet-2"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}

#Internet Gateway to attach to the VPC for internet access (attaching to public subnet here)

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-project-igw"
  }
}

resource "aws_route_table" "public_subnet_to_internet" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-subnet-route-table"
  }
}

#route table association for public subnets

resource "aws_route_table_association" "public_subnet_1" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_subnet_to_internet.id
}

resource "aws_route_table_association" "public_subnet_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_subnet_to_internet.id
}

#route table for private subnets
resource "aws_route_table" "private_subnet_to_internet" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-subnet-route-table"
  }
}

#route table association for public subnets

resource "aws_route_table_association" "private_subnet_1" {
  subnet_id      = aws_subnet.app_pvt_subnet_1.id
  route_table_id = aws_route_table.private_subnet_to_internet.id
}

resource "aws_route_table_association" "private_subnet_2" {
  subnet_id      = aws_subnet.app_pvt_subnet_2.id
  route_table_id = aws_route_table.private_subnet_to_internet.id
}