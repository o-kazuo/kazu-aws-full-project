# Secrets Managerにシークレットを作成
resource "aws_secretsmanager_secret" "db_secret" {
  name        = "kazu-db-secret"
  description = "kazu-6187"
}

# シークレットの中身（パスワード本体）
resource "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id = aws_secretsmanager_secret.db_secret.id

  secret_string = jsonencode({
    password = "kazu-6187"
  })
}