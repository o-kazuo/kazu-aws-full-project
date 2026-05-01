# -----------------------------------------------
# ここから追加：EC2用IAMロール（Secrets Manager連携）
# -----------------------------------------------

# 5. EC2が「なりすます」ためのロール本体
resource "aws_iam_role" "ec2_role" {
  name = "EC2-secrets-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# 6. Secrets Managerを覗く権限
resource "aws_iam_role_policy" "secrets_policy" {
  name = "secrets-manager-read"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = "*"
      }
    ]
  })
}

# 7. ロールをEC2に装着するためのインスタンスプロファイル
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2-secrets-profile"
  role = aws_iam_role.ec2_role.name
}

# 8. SSMセッションマネージャー用のポリシーをEC2ロールに追加
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}