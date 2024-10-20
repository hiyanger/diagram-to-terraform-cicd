provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "diagram-test"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "diagram-test"
  }
}

resource "aws_instance" "example" {
  ami           = "ami-0c3fd0f5d33134a76" # Amazon Linux 2 AMI in Tokyo region
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "diagram-test"
  }
}