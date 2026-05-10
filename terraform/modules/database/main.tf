# RDS Proxy用Secret（KMS暗号化なし・caching_sha2_password対応）
resource "aws_secretsmanager_secret" "rds_proxy" {
  name                    = "${var.env}-db-secret-proxy"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.env}-db-secret-proxy"
  }
}

resource "aws_secretsmanager_secret_version" "rds_proxy" {
  secret_id = aws_secretsmanager_secret.rds_proxy.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = "mysql"
    host     = aws_rds_cluster.main.endpoint
    port     = 3306
    dbname   = var.db_name
  })

  depends_on = [aws_rds_cluster.main]
}

# Aurora MySQLパラメータグループ
resource "aws_rds_cluster_parameter_group" "main" {
  name        = "${var.env}-aurora-mysql8-pg"
  family      = "aurora-mysql8.0"
  description = "Aurora MySQL 8.0 parameter group"

  parameter {
    name  = "require_secure_transport"
    value = "OFF"
  }



  tags = {
    Name = "${var.env}-aurora-mysql8-pg"
  }
}

# DBサブネットグループ
resource "aws_db_subnet_group" "main" {
  name       = "${var.env}-db-subnet-group"
  subnet_ids = var.db_subnets

  tags = {
    Name = "${var.env}-db-subnet-group"
  }
}

# DB用セキュリティグループ
resource "aws_security_group" "db" {
  name        = "${var.env}-db-sg"
  description = "Database security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.env}-db-sg"
  }
}

# Aurora Serverless v2 クラスター
resource "aws_rds_cluster" "main" {
  cluster_identifier     = "${var.env}-aurora-cluster"
  engine                 = "aurora-mysql"
  engine_version         = "8.0.mysql_aurora.3.08.0"
  database_name          = var.db_name
  master_username        = var.db_username
  master_password        = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  kms_key_id             = var.kms_key_arn
  storage_encrypted      = true
  skip_final_snapshot          = true
  deletion_protection          = false
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 4.0
  }

  tags = {
    Name = "${var.env}-aurora-cluster"
  }
}

# Aurora Serverless v2 インスタンス
resource "aws_rds_cluster_instance" "main" {
  identifier         = "${var.env}-aurora-instance-1"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  tags = {
    Name = "${var.env}-aurora-instance-1"
  }
}

# RDS Proxy用セキュリティグループ
resource "aws_security_group" "rds_proxy" {
  name        = "${var.env}-rds-proxy-sg"
  description = "RDS Proxy security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.env}-rds-proxy-sg"
  }
}

# RDS Proxy
resource "aws_db_proxy" "main" {
  name                   = "${var.env}-rds-proxy"
  debug_logging          = false
  engine_family          = "MYSQL"
  idle_client_timeout    = 1800
  require_tls            = true
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_security_group_ids = [aws_security_group.rds_proxy.id]
  vpc_subnet_ids         = var.db_subnets

  auth {
    auth_scheme               = "SECRETS"
    iam_auth                  = "DISABLED"
    secret_arn                = aws_secretsmanager_secret.rds_proxy.arn
    client_password_auth_type = "MYSQL_CACHING_SHA2_PASSWORD"
  }

  tags = {
    Name = "${var.env}-rds-proxy"
  }
}

# RDS ProxyをAuroraクラスターに紐付け
resource "aws_db_proxy_default_target_group" "main" {
  db_proxy_name = aws_db_proxy.main.name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "main" {
  db_cluster_identifier = aws_rds_cluster.main.id
  db_proxy_name         = aws_db_proxy.main.name
  target_group_name     = aws_db_proxy_default_target_group.main.name
}

# RDS Proxy→Aurora SGルール
resource "aws_security_group_rule" "rds_proxy_to_aurora" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db.id
  security_group_id        = aws_security_group.rds_proxy.id
  description              = "RDS Proxy to Aurora 3306"
}

resource "aws_security_group_rule" "aurora_from_rds_proxy" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds_proxy.id
  security_group_id        = aws_security_group.db.id
  description              = "Aurora from RDS Proxy 3306"
}

# RDS Proxy用IAMロール
resource "aws_iam_role" "rds_proxy" {
  name = "${var.env}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "rds.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.env}-rds-proxy-role"
  }
}

# RDS ProxyがSecrets Managerを読めるポリシー
resource "aws_iam_role_policy" "rds_proxy_secrets" {
  name = "${var.env}-rds-proxy-secrets-policy"
  role = aws_iam_role.rds_proxy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [aws_secretsmanager_secret.rds_proxy.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [var.kms_key_arn]
      }
    ]
  })
}

# RDS Proxyの全アウトバウンド通信許可
resource "aws_security_group_rule" "rds_proxy_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds_proxy.id
  description       = "RDS Proxy outbound all"
}

# Aurora DBの全アウトバウンド通信許可
resource "aws_security_group_rule" "db_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.db.id
  description       = "Aurora DB outbound all"
}

# ===== DynamoDB テーブル =====

# 月次AI使用回数管理
resource "aws_dynamodb_table" "user_usage" {
  name         = "${var.env}-user-usage"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  range_key    = "year_month"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "year_month"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = {
    Name = "${var.env}-user-usage"
  }
}

# AI処理履歴（リアルタイム）
resource "aws_dynamodb_table" "processing_history" {
  name         = "${var.env}-processing-history"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  range_key    = "created_at"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = {
    Name = "${var.env}-processing-history"
  }
}

# Lexチャット履歴
resource "aws_dynamodb_table" "chat_history" {
  name         = "${var.env}-chat-history"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  range_key    = "timestamp"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = {
    Name = "${var.env}-chat-history"
  }
}

# Macie PII検出記録
resource "aws_dynamodb_table" "macie_findings" {
  name         = "${var.env}-macie-findings"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "bucket_name"
  range_key    = "finding_id"

  attribute {
    name = "bucket_name"
    type = "S"
  }

  attribute {
    name = "finding_id"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  tags = {
    Name = "${var.env}-macie-findings"
  }
}

resource "aws_security_group_rule" "ecs_to_aurora" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = var.app_sg_ids[0]
  security_group_id        = aws_security_group.db.id
  description              = "ECS migration task to Aurora direct"
}

resource "aws_security_group_rule" "aurora_from_ecs" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = var.app_sg_ids[0]
  security_group_id        = aws_security_group.db.id
  description              = "Aurora from ECS migration task"
}

# RDS Proxy Readerエンドポイント
resource "aws_db_proxy_endpoint" "reader" {
  db_proxy_name          = aws_db_proxy.main.name
  db_proxy_endpoint_name = "${var.env}-rds-proxy-reader"
  vpc_subnet_ids         = var.db_subnets
  vpc_security_group_ids = [aws_security_group.rds_proxy.id]
  target_role            = "READ_ONLY"

  tags = {
    Name = "${var.env}-rds-proxy-reader"
  }
}