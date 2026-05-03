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
  name       = "${var.env}-db-secret-v2"
  recovery_window_in_days = 0
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

# EC2 IAMロール
resource "aws_iam_role" "ec2" {
  name = "${var.env}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Name = "${var.env}-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_secrets" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

# Batch用セキュリティグループ
resource "aws_security_group" "batch" {
  name        = "${var.env}-batch-sg"
  description = "Security group for AWS Batch"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.env}-batch-sg" }
}