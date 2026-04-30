# 1. VPCの定義
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    # ★好きなVPC名に変更してください
    Name = "kazu-vpc"
  }
}

# 2. パブリックサブネット (Web/ALB用)
resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    # ★好きな名前に変更してください
    Name = "kazu-public-ALB-1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    Name = "kazu-public-ALB-1c"
  }
}

# 3. プライベートサブネット (App層)
resource "aws_subnet" "app_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "kazu-app-private-App-1a"
  }
}

resource "aws_subnet" "app_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    Name = "kazu-app-private-App-1c"
  }
}

# 4. プライベートサブネット (DB層)
resource "aws_subnet" "db_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "kazu-db-private-DB-1a"
  }
}

resource "aws_subnet" "db_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    Name = "kazu-db-private-DB-1c"
  }
}

# 5. S3用ゲートウェイエンドポイント
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.ap-northeast-1.s3"
  tags = {
    Name = "kazu-s3-endpoint"
  }
}
