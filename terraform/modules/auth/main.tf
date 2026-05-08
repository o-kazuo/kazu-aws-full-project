# Cognito ユーザープール
resource "aws_cognito_user_pool" "main" {
  name = "${var.env}-user-pool"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  tags = {
    Name = "${var.env}-user-pool"
  }
}

# Cognito ユーザープールクライアント
resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.env}-user-pool-client"
  user_pool_id = aws_cognito_user_pool.main.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  generate_secret = false
}

# API Gateway
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.env}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["*"]
  }

  tags = {
    Name = "${var.env}-api"
  }
}

# API Gateway ステージ
resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = var.env
  auto_deploy = true

  tags = {
    Name = "${var.env}-api-stage"
  }
}

# JWT オーサライザー（Cognito連携）
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.env}-cognito-authorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.main.id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
  }
}

# テストユーザーパスワードをSecretsManagerで管理
resource "aws_secretsmanager_secret" "test_user" {
  name       = "${var.env}-test-user-secret"
  kms_key_id = var.kms_key_id
  tags = {
    Name = "${var.env}-test-user-secret"
  }
}

resource "aws_secretsmanager_secret_version" "test_user" {
  secret_id     = aws_secretsmanager_secret.test_user.id
  secret_string = jsonencode({
    username = "hokkaido.nan@gmail.com"
    password = "Kazu6187!"
  })
}

# テストユーザー作成
resource "aws_cognito_user" "test_user" {
  user_pool_id = aws_cognito_user_pool.main.id
  username     = jsondecode(aws_secretsmanager_secret_version.test_user.secret_string)["username"]
  password     = jsondecode(aws_secretsmanager_secret_version.test_user.secret_string)["password"]

  attributes = {
    email          = jsondecode(aws_secretsmanager_secret_version.test_user.secret_string)["username"]
    email_verified = "true"
  }
}