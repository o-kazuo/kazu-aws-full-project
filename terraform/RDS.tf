# DBサブネットグループの作成
resource "aws_db_subnet_group" "main" {
  name       = "kazu-db-subnet-group"
  
  # vpc.tfで定義された「リソース名」を正しく指定
  subnet_ids = [
    aws_subnet.db_1a.id, 
    aws_subnet.db_1c.id
  ]

  tags = {
    Name = "kazu-db-subnet-group"
  }
}

# RDS用のセキュリティグループ
resource "aws_security_group" "db_sg" {
  name        = "kazu-db-sg"
  description = "Allow inbound traffic from EC2"
  vpc_id      = aws_vpc.main.id # vpc.tfで定義したVPCリソース名に合わせてください

  # EC2からのMySQL（3306）接続を許可
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    # ここがポイント：EC2のセキュリティグループを指定
    security_groups = [aws_security_group.web_sg.id] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kazu-db-sg"
  }
}

# RDSインスタンス本体
resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  
  db_name              = "kazu_DB" # 最初に作成されるデータベース名
  username             = "admin"
  password = jsondecode(aws_secretsmanager_secret_version.db_secret_value.secret_string)["password"]
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true # 削除時にバックアップを取らない（学習・テスト用）

  # ☆追加：マルチAZ有効化
  multi_az = true

  # 先ほど作ったグループを紐付け
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = "kazu-main-db"
  }
}

# 接続先（エンドポイント）を確認するための出力設定
output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

