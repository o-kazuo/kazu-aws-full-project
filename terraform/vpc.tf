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

# インターネットゲートウェイの作成
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    # ★好きなゲートウェイ名（例: kazu-igw）
    Name = "kazu-IGW"
  }
}

# ルートテーブル(public)の作成
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    # ★好きなルートテーブル名（例: kazu-public-rt）
    Name = "kazu-RTB-public-IGW"
  }
}

# サブネットとの紐づけ(pablic)
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

/* 
# =====================================================
# 【将来用：NATゲートウェイ爆弾】
# 使う時は、各行の先頭にあるハッシュ記号を消して実行
# =====================================================

# 1. NATゲートウェイ用の固定IP（EIP）
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "kazu-nat-eip" }
}

# 2. NATゲートウェイ本体（パブリックサブネットに配置）
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1a.id # 1a側の玄関に設置
  tags          = { Name = "kazu-nat-gw" }

  # インターネットゲートウェイが先にできていることを確実にする
  depends_on = [aws_internet_gateway.main]
}

# 3. プライベートサブネット用のルートテーブル（NAT経由で外へ）
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = { Name = "kazu-private-rt" }
}

# 4. App層/DB層のサブネットをこのルートテーブルに紐付け
resource "aws_route_table_association" "app_1a" {
  subnet_id      = aws_subnet.app_1a.id
  route_table_id = aws_route_table.private.id
}
# ...（1cやDB層も同様に紐付けるコードをここに並べる）
*/
