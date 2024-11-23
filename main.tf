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

resource "aws_s3_bucket" "diagram" {
  bucket = "hiyama-bedrock-20241123-1"

  tags = {
    Name = "diagram-s3"
  }
}

resource "aws_s3_bucket_versioning" "diagram" {
  bucket = aws_s3_bucket.diagram.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "diagram" {
  bucket = aws_s3_bucket.diagram.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "diagram" {
  bucket = aws_s3_bucket.diagram.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}