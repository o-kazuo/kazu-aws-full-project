# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.env}-vpc"
  }
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-igw"
  }
}

# パブリックサブネット1a
resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnets[0]
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.env}-public-1a"
  }
}

# パブリックサブネット1c
resource "aws_subnet" "public_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnets[1]
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "${var.env}-public-1c"
  }
}

# プライベートサブネット1a（アプリ用）
resource "aws_subnet" "app_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnets[0]
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.env}-app-1a"
  }
}

# プライベートサブネット1c（アプリ用）
resource "aws_subnet" "app_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnets[1]
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "${var.env}-app-1c"
  }
}

# プライベートサブネット1a（DB用）
resource "aws_subnet" "db_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnets[0]
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.env}-db-1a"
  }
}

# プライベートサブネット1c（DB用）
resource "aws_subnet" "db_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnets[1]
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "${var.env}-db-1c"
  }
}

# パブリックルートテーブル
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.env}-public-rt"
  }
}

# パブリックサブネットにルートテーブルを関連付け
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

# （既存コードはそのまま）

# ===== ここから追加 =====

# プライベートサブネット1a（Cache用）
resource "aws_subnet" "cache_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cache_subnets[0]
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.env}-cache-1a"
  }
}

# プライベートサブネット1c（Cache用）
resource "aws_subnet" "cache_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cache_subnets[1]
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "${var.env}-cache-1c"
  }
}

# Elastic IP（NAT Gateway用）
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.env}-nat-eip"
  }
}

# NAT Gateway（パブリックサブネット1aに配置）
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1a.id

  tags = {
    Name = "${var.env}-nat-gw"
  }

  depends_on = [aws_internet_gateway.main]
}

# プライベートルートテーブル（アプリ・DB・Cache用）
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.env}-private-rt"
  }
}

# プライベートサブネットにルートテーブルを関連付け
resource "aws_route_table_association" "app_1a" {
  subnet_id      = aws_subnet.app_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "app_1c" {
  subnet_id      = aws_subnet.app_1c.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db_1a" {
  subnet_id      = aws_subnet.db_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db_1c" {
  subnet_id      = aws_subnet.db_1c.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "cache_1a" {
  subnet_id      = aws_subnet.cache_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "cache_1c" {
  subnet_id      = aws_subnet.cache_1c.id
  route_table_id = aws_route_table.private.id
}