provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_vpc" "diagram_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "diagram-vpc"
  }
}

resource "aws_subnet" "diagram_public_subnet" {
  vpc_id     = aws_vpc.diagram_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "diagram-public-subnet"
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

resource "aws_security_group" "diagram_sg" {
  name        = "diagram-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.diagram_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "diagram-sg"
  }
}

resource "aws_instance" "diagram_ec2" {
  ami           = "ami-06b21ccaeff8cd686" # AL2023
  instance_type = "t2.micro"
  key_name      = "hiyama-diagram"
  subnet_id     = aws_subnet.diagram_public_subnet.id
  vpc_security_group_ids = [aws_security_group.diagram_sg.id]

  tags = {
    Name = "diagram-ec2"
  }
}