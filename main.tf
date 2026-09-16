#VPC

resource "aws_vpc" "main" {
  cidr_block = "12.0.0.0/16"
}

#subnets

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "12.0.1.0/24"

  tags = {
    Name = "private-subnet"
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
  vpc_id     = aws_vpc.main.id
  cidr_block = "12.0.2.0/24"

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "12.0.4.0/24"

  tags = {
    Name = "public-subnet-2"
  }
}   