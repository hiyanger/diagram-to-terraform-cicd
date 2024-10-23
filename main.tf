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

resource "aws_vpc" "diagram" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "diagram-vpc"
  }
}

resource "aws_internet_gateway" "diagram" {
  vpc_id = aws_vpc.diagram.id
  tags = {
    Name = "diagram-igw"
  }
}

resource "aws_subnet" "diagram" {
  vpc_id     = aws_vpc.diagram.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "diagram-subnet"
  }
}

resource "aws_route_table" "diagram" {
  vpc_id = aws_vpc.diagram.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.diagram.id
  }
  tags = {
    Name = "diagram-rt"
  }
}

resource "aws_route_table_association" "diagram" {
  subnet_id      = aws_subnet.diagram.id
  route_table_id = aws_route_table.diagram.id
}

resource "aws_security_group" "diagram" {
  name        = "diagram-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.diagram.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 適宜変更
  }

  tags = {
    Name = "diagram-sg"
  }
}

resource "aws_instance" "diagram" {
  ami                         = "ami-03f584e50b2d32776" # AL2023
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.diagram.id
  vpc_security_group_ids      = [aws_security_group.diagram.id]
  associate_public_ip_address = true
  key_name                    = "hiyama-diagram"

  tags = {
    Name = "diagram-ec2"
  }
}

resource "aws_ecs_cluster" "diagram" {
  name = "diagram-cluster"
  tags = {
    Name = "diagram-ecs-cluster"
  }
}

resource "aws_ecs_task_definition" "diagram" {
  family                   = "diagram-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name  = "diagram-container"
      image = "nginx:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

  tags = {
    Name = "diagram-ecs-task-definition"
  }
}

resource "aws_ecs_service" "diagram" {
  name            = "diagram-service"
  cluster         = aws_ecs_cluster.diagram.id
  task_definition = aws_ecs_task_definition.diagram.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.diagram.id]
    security_groups  = [aws_security_group.diagram.id]
    assign_public_ip = true
  }

  tags = {
    Name = "diagram-ecs-service"
  