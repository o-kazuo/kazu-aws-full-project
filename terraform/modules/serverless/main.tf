# フロントエンド用S3バケット
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.env}-frontend-${var.account_id}"

  tags = {
    Name = "${var.env}-frontend"
  }
}

# フロントエンドバケット パブリックアクセスブロック（OAC経由のみ許可）
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# フロントエンドバケット 暗号化
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# フロントエンドバケット バージョニング
resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3入力バケット
resource "aws_s3_bucket" "input" {
  bucket = "${var.env}-input-bucket-${var.account_id}"

  tags = {
    Name = "${var.env}-input-bucket"
  }
}

# S3出力バケット
resource "aws_s3_bucket" "output" {
  bucket = "${var.env}-output-bucket-${var.account_id}"

  tags = {
    Name = "${var.env}-output-bucket"
  }
}

# S3入力バケット暗号化
resource "aws_s3_bucket_server_side_encryption_configuration" "input" {
  bucket = aws_s3_bucket.input.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

# S3出力バケット暗号化
resource "aws_s3_bucket_server_side_encryption_configuration" "output" {
  bucket = aws_s3_bucket.output.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

# SNSトピック
resource "aws_sns_topic" "notification" {
  name = "${var.env}-notification"

  tags = {
    Name = "${var.env}-notification"
  }
}

# SNSサブスクリプション（メール通知）
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.notification.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# Lambda用インラインポリシー（S3・Rekognition・DynamoDB・SNS）
resource "aws_iam_role_policy" "lambda_main" {
  name = "${var.env}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # S3アクセス（input読み取り・output書き込み）
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.input.arn}/*",
          "${aws_s3_bucket.output.arn}/*"
        ]
      },
      {
        # Rekognition（画像分析）
        Sid    = "RekognitionAccess"
        Effect = "Allow"
        Action = [
          "rekognition:DetectLabels",
          "rekognition:DetectFaces",
          "rekognition:DetectText"
        ]
        Resource = "*"
      },
      {
        # DynamoDB（分析結果保存）
        Sid    = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${var.account_id}:table/${var.env}-image-analysis"
      },
      {
        # SNS通知
        Sid    = "SNSAccess"
        Effect = "Allow"
        Action = ["sns:Publish"]
        Resource = aws_sns_topic.notification.arn
      },
      {
        # KMS復号（S3暗号化対応）
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arn
      }
    ]
  })
}

# Lambda IAMロール
resource "aws_iam_role" "lambda" {
  name = "${var.env}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = {
    Name = "${var.env}-lambda-role"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda関数
resource "aws_lambda_function" "image_resize" {
  filename         = var.lambda_zip_path
  function_name    = "${var.env}-image-resize"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  timeout = 60  # ← 追加（60秒に延長）
  memory_size = 512  # ← 追加（128MB→512MBに増やす）

  environment {
    variables = {
      OUTPUT_BUCKET  = aws_s3_bucket.output.bucket
      SNS_TOPIC_ARN  = aws_sns_topic.notification.arn
      DYNAMODB_TABLE = "${var.env}-image-analysis"
      AWS_ACCOUNT_ID = var.account_id
    }
  }

  tags = {
    Name = "${var.env}-image-resize"
  }
}

# S3からLambdaへのトリガー
resource "aws_s3_bucket_notification" "input" {
  bucket = aws_s3_bucket.input.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_resize.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "images/"
  }

  depends_on = [aws_lambda_permission.s3]
}

resource "aws_lambda_permission" "s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_resize.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.input.arn
}

# 画像分析結果テーブル
resource "aws_dynamodb_table" "image_analysis" {
  name         = "${var.env}-image-analysis"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "image_key"
  range_key    = "analyzed_at"

  attribute {
    name = "image_key"
    type = "S"
  }

  attribute {
    name = "analyzed_at"
    type = "S"
  }

  # ラベル検索用GSI
  global_secondary_index {
    name            = "label-index"
    hash_key        = "top_label"
    projection_type = "ALL"
  }

  attribute {
    name = "top_label"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = {
    Name = "${var.env}-image-analysis"
  }
}

# CloudTrail専用ログバケット
resource "aws_s3_bucket" "cloudtrail" {
  bucket = "${var.env}-cloudtrail-${var.account_id}"

  tags = {
    Name = "${var.env}-cloudtrail"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket                  = aws_s3_bucket.cloudtrail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}