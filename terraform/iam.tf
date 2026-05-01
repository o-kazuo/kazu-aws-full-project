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
