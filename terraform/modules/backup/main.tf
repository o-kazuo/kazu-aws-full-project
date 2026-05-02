# AWS Backupボールト
resource "aws_backup_vault" "main" {
  name        = "${var.env}-backup-vault"
  kms_key_arn = var.kms_key_arn

  tags = {
    Name = "${var.env}-backup-vault"
  }
}

# AWS Backupプラン
resource "aws_backup_plan" "main" {
  name = "${var.env}-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 2 * * ? *)"
    
    lifecycle {
      delete_after = 35
    }
  }

  tags = {
    Name = "${var.env}-backup-plan"
  }
}

# AWS Backup IAMロール
resource "aws_iam_role" "backup" {
  name = "${var.env}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Aurora クラスターをバックアップ対象に追加
resource "aws_backup_selection" "aurora" {
  name         = "${var.env}-aurora-backup"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = var.backup_resources
}