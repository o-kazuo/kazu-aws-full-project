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
  name       = "${var.env}-app-secret"
  recovery_window_in_days = 0
  kms_key_id = aws_kms_key.main.arn

  tags = {
    Name = "${var.env}-db-secret"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    DATABASE_URL_WRITER = "mysql+pymysql://${var.db_username}:${var.db_password}@${var.rds_proxy_endpoint}:3306/${var.db_name}"
    DATABASE_URL_READER = "mysql+pymysql://${var.db_username}:${var.db_password}@${var.rds_proxy_reader_endpoint}:3306/${var.db_name}"
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
# GitHub Actions OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHubのOIDC証明書のサムプリント（固定値）
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# GitHub Actions用IAMロール（ユーザーの代わり）
resource "aws_iam_role" "github_actions" {
  name = "${var.env}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # リポジトリ名を限定（セキュリティ上重要！）
          "token.actions.githubusercontent.com:sub" = "repo:o-kazuo/kazu-aws-full-project:*"
        }
      }
    }]
  })

  tags = {
    Name = "${var.env}-github-actions-role"
  }
}

# ポリシーはそのまま流用（userからroleに付け替えるだけ）
resource "aws_iam_role_policy" "github_actions" {
  name = "${var.env}-github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECSDescribeAccess"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeServices",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECSWriteAccess"
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
          "ecs:RunTask",
          "ecs:WaitUntilTasksStopped",
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:ecs:${var.aws_region}:${var.account_id}:cluster/${var.env}-ecs-cluster",
          "arn:aws:ecs:${var.aws_region}:${var.account_id}:service/${var.env}-ecs-cluster/${var.env}-web-service",
          "arn:aws:ecs:${var.aws_region}:${var.account_id}:task-definition/${var.env}-web-task:*",
          "arn:aws:ecs:${var.aws_region}:${var.account_id}:task-definition/${var.env}-migration-task:*",
          "arn:aws:ecs:${var.aws_region}:${var.account_id}:task/${var.env}-ecs-cluster/*"
        ]
      },
      {
        Sid    = "ECSAccess"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:RunTask",
          "ecs:DescribeTasks",
          "ecs:WaitUntilTasksStopped",
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:ecs:${var.aws_region}:${var.account_id}:cluster/${var.env}-ecs-cluster",
          "arn:aws:ecs:${var.aws_region}:${var.account_id}:service/${var.env}-ecs-cluster/${var.env}-web-service",
          "arn:aws:ecs:${var.aws_region}:${var.account_id}:task-definition/${var.env}-web-task:*",
          "arn:aws:ecs:${var.aws_region}:${var.account_id}:task-definition/${var.env}-migration-task:*",
          "arn:aws:ecs:${var.aws_region}:${var.account_id}:task/${var.env}-ecs-cluster/*"
        ]
      },
      {
        Sid    = "EC2Access"
        Effect = "Allow"
        Action = [
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.env}-frontend-${var.account_id}",
          "arn:aws:s3:::${var.env}-frontend-${var.account_id}/*"
        ]
      },
      {
        Sid    = "ALBAccess"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudFrontAccess"
        Effect = "Allow"
        Action = [
          "cloudfront:ListDistributions",
          "cloudfront:CreateInvalidation"
        ]
        Resource = "*"
      },
      {
        Sid    = "IAMPassRole"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::${var.account_id}:role/${var.env}-ecs-task-execution-role",
          "arn:aws:iam::${var.account_id}:role/${var.env}-ecs-task-role"
        ]
      }
    ]
  })
}