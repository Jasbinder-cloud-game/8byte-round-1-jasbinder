#VPC

resource "aws_vpc" "main" {
  cidr_block = "12.0.0.0/16"

  tags = {
    Name = "my-project-vpc" # This sets the display name in AWS
  }
}

#subnets - 2 private and 2 public

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "12.0.1.0/24"

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "12.0.3.0/24"

  tags = {
    Name = "private-subnet-2"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "12.0.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "12.0.4.0/24"
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