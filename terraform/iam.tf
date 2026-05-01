# 1. ユーザー本体（ここで「admin」という名前を定義しています）
resource "aws_iam_user" "admin" {
  # ★ここを「好きなログイン名」に書き換えてください
  name = "admin-kazu2"
  path = "/"
}

# 2. ログインパスワードの設定
resource "aws_iam_user_login_profile" "admin_login" {
  user                    = aws_iam_user.admin.name
  password_reset_required = true
}

# 3. 管理者権限の付与
resource "aws_iam_user_policy_attachment" "admin_attach" {
  user       = aws_iam_user.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 4. パスワードを画面に表示
output "initial_password" {
  value     = aws_iam_user_login_profile.admin_login.password
  sensitive = true
}

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