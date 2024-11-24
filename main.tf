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
  bucket = "deploy-s3"
  tags = {
    Name = "deploy-s3"
  }
}