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

resource "aws_lambda_function" "deploy" {
  filename      = "lambda_function.zip"
  function_name = "deploy"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  tags = {
    Name = "deploy-lambda"
  }
}

resource "aws_iam_role" "lambda" {
  name = "lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "deploy-lambda-role"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_s3_bucket" "deploy" {
  bucket = "deploy-bucket"

  tags = {
    Name = "deploy-s3"
  }
}

resource "aws_api_gateway_rest_api" "deploy" {
  name = "deploy-api"

  tags = {
    Name = "deploy-apigateway"
  }
}

resource "aws_api_gateway_resource" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.deploy.id
  parent_id   = aws_api_gateway_rest_api.deploy.root_resource_id
  path_part   = "resource"
}

resource "aws_api_gateway_method" "deploy" {
  rest_api_id   = aws_api_gateway_rest_api.deploy.id
  resource_id   = aws_api_gateway_resource.deploy.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.deploy.id
  resource_id = aws_api_gateway_resource.deploy.id
  http_method = aws_api_gateway_method.deploy.http_method
  type        = "AWS_PROXY"
  uri         = aws_lambda_function.deploy.invoke_arn
  integration_http_method = "POST"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.deploy.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.deploy.execution_arn}/*/*"
}

# AL2023
resource "aws_instance" "deploy" {
  ami           = "ami-03f584e50b2d32776"
  instance_type = "t2.micro"
  key_name      = "hiyama-diagram"
  vpc_security_group_ids = [aws_security_group.deploy.id]
  associate_public_ip_address = true

  tags = {
    Name = "deploy-ec2"
  }
}

resource "aws_security_group" "deploy" {
  name = "deploy-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks =