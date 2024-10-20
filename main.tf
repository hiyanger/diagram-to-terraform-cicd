provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_vpc" "diagram_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "diagram-vpc"
  }
}

resource "aws_subnet" "diagram_public_subnet" {
  vpc_id     = aws_vpc.diagram_vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "diagram-public-subnet"
  }
}

resource "aws_instance" "diagram_ec2" {
  ami           = "ami-0c3fd0f5d33134a76" # Amazon Linux 2 AMI in Tokyo region
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.diagram_public_subnet.id
  tags = {
    Name = "diagram-ec2"
  }
}

resource "aws_internet_gateway" "diagram_igw" {
  vpc_id = aws_vpc.diagram_vpc.id
  tags = {
    Name = "diagram-igw"
  }
}

resource "aws_route_table" "diagram_public_rt" {
  vpc_id = aws_vpc.diagram_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.diagram_igw.id
  }
  tags = {
    Name = "diagram-public-rt"
  }
}

resource "aws_route_table_association" "diagram_public_rta" {
  subnet_id      = aws_subnet.diagram_public_subnet.id
  route_table_id = aws_route_table.diagram_public_rt.id
}