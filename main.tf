variable "aws_access_key_id" {
  type = string
}

variable "aws_secret_access_key" {
  type = string
}

provider "aws" {
  region     = "ap-northeast-1"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

resource "aws_instance" "diagram" {
  ami           = "ami-03f584e50b2d32776"  # AL2023
  instance_type = "t2.micro"
  key_name      = "hiyama-diagram"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.diagram.id]

  tags = {
    Name = "diagram-ec2"
  }
}

resource "aws_security_group" "diagram" {
  name = "diagram-sg"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 適宜変更
  }

  tags = {
    Name = "diagram-sg"
  }
}