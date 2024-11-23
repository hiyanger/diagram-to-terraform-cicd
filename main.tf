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
}

resource "aws_cloudfront_distribution" "deploy" {
  enabled = true
  
  origin {
    domain_name = aws_s3_bucket.deploy.bucket_regional_domain_name
    origin_id   = "S3Origin"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.deploy.cloudfront_access_identity_path
    }
  }
  
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    
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

resource "aws_cloudfront_origin_access_identity" "deploy" {}

resource "aws_lambda_function" "deploy" {
  filename         = "lambda.zip"
  function_name    = "deploy-lambda"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  
  tags = {
    Name = "deploy-lambda"
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
  name = "deploy-lambda-role"
  
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

resource "aws_instance" "deploy" {
  ami           = "ami-03f584e50b2d32776" # AL2023
  instance_type = "t2.micro"
  key_name      = "hiyama-diagram"
  
  vpc_security_group_ids = [aws_security_group.deploy.id]
  
  associate_public_ip_address = true
  
  tags = {
    Name = "deploy-ec2"
  }
}

resource "aws_security_group" "deploy" {
  name        = "deploy-sg"
  description = "Security group for EC2"
  
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