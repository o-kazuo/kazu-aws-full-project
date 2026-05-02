# KMSキー
resource "aws_kms_key" "main" {
  description             = "${var.env}-main-key"
  deletion_window_in_days = 7

  tags = {
    Name = "${var.env}-main-key"
  }
}

# KMSエイリアス
resource "aws_kms_alias" "main" {
  name          = "alias/${var.env}-main-key"
  target_key_id = aws_kms_key.main.key_id
}

# Secrets Manager（DBパスワード）
resource "aws_secretsmanager_secret" "db" {
  name       = "${var.env}-db-secret"
  kms_key_id = aws_kms_key.main.arn

  tags = {
    Name = "${var.env}-db-secret"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}