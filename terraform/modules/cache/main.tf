# Cache用サブネットグループ
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.env}-cache-subnet-group"
  subnet_ids = var.cache_subnets

  tags = {
    Name = "${var.env}-cache-subnet-group"
  }
}

# Cache用セキュリティグループ
resource "aws_security_group" "cache" {
  name        = "${var.env}-cache-sg"
  description = "ElastiCache security group"
  vpc_id      = var.vpc_id

  # アプリからRedisへの接続のみ許可
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = var.app_sg_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-cache-sg"
  }
}

# ElastiCache Redis（Replication Group = マルチAZ）
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.env}-redis"
  description          = "KazuAI Platform Redis cache"

  node_type            = "cache.t4g.micro"  # 開発環境は最小スペック
  port                 = 6379
  parameter_group_name = "default.redis7"

  # マルチAZ設定
  num_cache_clusters         = 2  # プライマリ1 + レプリカ1
  automatic_failover_enabled = true
  multi_az_enabled           = true

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.cache.id]

  # 暗号化
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  # 自動バックアップ（1日1回、1世代保持）
  snapshot_retention_limit = 1
  snapshot_window          = "03:00-04:00"  # 深夜3時（JST 12時）

  # メンテナンスウィンドウ
  maintenance_window = "sun:04:00-sun:05:00"  # 日曜深夜

  tags = {
    Name = "${var.env}-redis"
  }
}