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

resource "aws_instance" "deploy" {
  ami           = "ami-03f584e50b2d32776" # AL2023
  instance_type = "t2.micro"
  key_name      = "hiyama-diagram"

  vpc_security_group_ids = [aws_security_group.deploy.id]

  tags = {
    Name = "deploy-ec2"
  }
}

resource "aws_security_group" "deploy" {
  name = "deploy"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 適宜変更
  }

  tags = {
    Name = "deploy-sg"
  }
}

resource "aws_s3_bucket" "deploy" {
  bucket = "deploy-bucket"

  tags = {
    Name = "deploy-s3"
  }
}