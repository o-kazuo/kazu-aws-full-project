# AWS Organizations
resource "aws_organizations_organization" "main" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com",
    "backup.amazonaws.com",
  ]

  feature_set = "ALL"
}

# 開発OUの作成
resource "aws_organizations_organizational_unit" "dev" {
  name      = "Development"
  parent_id = aws_organizations_organization.main.roots[0].id

  tags = {
    Name = "Development-OU"
  }
}

# 本番OUの作成
resource "aws_organizations_organizational_unit" "prod" {
  name      = "Production"
  parent_id = aws_organizations_organization.main.roots[0].id

  tags = {
    Name = "Production-OU"
  }
}

# SCP（S3パブリックアクセス禁止）
resource "aws_organizations_policy" "deny_s3_public" {
  name        = "DenyS3PublicAccess"
  description = "S3バケットのパブリックアクセスを禁止"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Deny"
      Action   = [
        "s3:PutBucketPublicAccessBlock",
        "s3:DeletePublicAccessBlock"
      ]
      Resource = "*"
      Condition = {
        Bool = {
          "s3:DataAccessPointArn" = "false"
        }
      }
    }]
  })
}

# CloudTrail用S3バケットポリシー
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = var.cloudtrail_bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${var.cloudtrail_bucket}"
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.cloudtrail_bucket}/AWSLogs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# CloudTrail（全API操作の監査ログ）
resource "aws_cloudtrail" "main" {
  depends_on = [aws_s3_bucket_policy.cloudtrail]
  name                          = "${var.env}-cloudtrail"
  s3_bucket_name                = var.cloudtrail_bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  tags = {
    Name = "${var.env}-cloudtrail"
  }
}