terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS 리전 설정
provider "aws" {
  region = var.aws_region
}

# 버킷
resource "aws_s3_bucket" "image_bucket" {
  bucket = var.s3_bucket_name
}

# 버킷의 퍼블릭 접근 제어 정책 설정, 버킷을 퍼블릭으로 설정
resource "aws_s3_bucket_public_access_block" "image_bucket_pab" {
  bucket = aws_s3_bucket.image_bucket.id

  block_public_acls = false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false
}

# 버킷의 모든 파일을 퍼블릭으로 읽을 수 있도록 설정
data "aws_iam_policy_document" "bucket_policy_statement" {
  statement {
    sid = "PublicReadGetObject"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = ["*"]
    }

    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.image_bucket.arn}/*"]
  }
}

# 정책을 버킷에 적용
resource "aws_s3_bucket_policy" "image_bucket_policy" {
  bucket = aws_s3_bucket.image_bucket.id

  policy = data.aws_iam_policy_document.bucket_policy_statement.json

  depends_on = [aws_s3_bucket_public_access_block.image_bucket_pab]
}

# 람다 role 관련 데이터 소스
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# 람다 관련 role
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

# 람다 정책 관련 데이터 소스
data "aws_iam_policy_document" "lambda_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.image_bucket.arn}/*"]
  }
}

# 람다 role에 로그 기록과 S3 접근 권한을 부여하는 정책
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = data.aws_iam_policy_document.lambda_policy_document.json
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/thumbnail-generator.zip"
  output_path = "${path.module}/thumbnail-generator.zip"
}

# 람다 함수 생성
resource "aws_lambda_function" "thumbnail_generator" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-thumbnail-generator"
  role             = aws_iam_role.lambda_role.arn
  handler          = "thumbnail-generator.lambda_handler"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime          = "python3.9"
  timeout          = 30
  memory_size      = 512

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.image_bucket.id
    }
  }
}

# 버킷에 파일이 생성되면 자동으로 람다 함수 호출되도록
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.image_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.thumbnail_generator.arn
    events = ["s3:ObjectCreated:*"]
    filter_prefix = "original/"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

# 버킷이 람다를 호출할 수 있도록 허용
resource "aws_lambda_permission" "allow_bucket" {
  statement_id = "AllowExecutionFromS3Bucket"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.thumbnail_generator.function_name
  principal = "s3.amazonaws.com"
  source_arn = aws_s3_bucket.image_bucket.arn
}

# VPC
resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Subnets
resource "aws_subnet" "public_a" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-b"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "${var.aws_region}c"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-c"
  }
}

# Route Table
resource "aws_route_table" "my-route-table" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }

  tags = {
    Name = "${var.project_name}-public"
  }
}

# Route table associations
resource "aws_route_table_association" "public_a" {
  subnet_id = aws_subnet.public_a.id
  route_table_id = aws_route_table.my-route-table.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id = aws_subnet.public_b.id
  route_table_id = aws_route_table.my-route-table.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id = aws_subnet.public_c.id
  route_table_id = aws_route_table.my-route-table.id
}

# Security Group
resource "aws_security_group" "my-sg" {
  name_prefix = "${var.project_name}-db-ec2-"
  vpc_id = aws_vpc.my-vpc.id

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-ec2-sg"
  }
}

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}

# EC2 role에 AmazonS3FullAccess 정책을 부착
resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# EC2 role에 AmazonEC2RoleforSSM 정책을 부착
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

# IAM 인스턴스 프로파일 생성
resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2
resource "aws_instance" "my-ec2" {
  ami = "ami-07eff2bc4837a9e01"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  subnet_id = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.my-sg.id]
  associate_public_ip_address = true

  # EC2 인스턴스 부팅 시 MySQL 설치
  user_data = <<-EOF
              #!/bin/bash
              yum update -y

              yum install -y docker
              systemctl start docker
              systemctl enable docker

              usermod -a -G docker ec2-user

              docker run -d \
                --name mysql-server \
                -p 3306:3306 \
                -e MYSQL_ROOT_PASSWORD=${var.db_password} \
                -e MYSQL_DATABASE=${var.db_name} \
                -e MYSQL_USER=${var.db_user} \
                -e MYSQL_PASSWORD=${var.db_password} \
                --restart=always \
                mysql:8.0
              EOF

  tags = {
    Name = "${var.project_name}-mysql-server"
  }
}
