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

  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.output.bucket
      SNS_TOPIC_ARN = aws_sns_topic.notification.arn
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