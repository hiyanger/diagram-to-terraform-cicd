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

resource "aws_s3_bucket" "deploy" {
  bucket = "deploy-bucket"

  tags = {
    Name = "deploy-s3"
  }
}

resource "aws_cloudfront_distribution" "deploy" {
  origin {
    domain_name = aws_s3_bucket.deploy.bucket_regional_domain_name
    origin_id   = "S3Origin"
  }

  enabled = true
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "allow-all"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "deploy-cloudfront"
  }
}

resource "aws_dynamodb_table" "deploy" {
  name           = "deploy-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "deploy-dynamodb"
  }
}

resource "aws_iam_role" "lambda" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "deploy-lambda-role"
  }
}

resource "aws_lambda_function" "deploy" {
  filename         = "lambda.zip"
  function_name    = "deploy-function"
  role            = aws_iam_role.lambda.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"

  tags = {
    Name = "deploy-lambda"
  }
}

resource "aws_vpc" "deploy" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "deploy-vpc"
  }
}

resource "aws_subnet" "deploy" {
  vpc_id     = aws_vpc.deploy.id
  cidr_block = "10.0.1.0/24"
  
  tags = {
    Name = "deploy-subnet"
  }
}

resource "aws_security_group" "deploy" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.deploy.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 適宜変更
  }

  tags = {
    Name = "deploy-sg"
  }
}

resource "aws_instance" "deploy" {
  ami           = "ami-03f584e50b2d32776"  # AL2023
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.deploy.id
  key_name      = "hiyama-diagram"
  
  vpc_security_group_ids = [aws_security_group.deploy