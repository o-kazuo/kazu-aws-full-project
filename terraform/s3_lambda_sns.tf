# -----------------------------------------------
# S3バケット（入力）
# -----------------------------------------------
resource "aws_s3_bucket" "input" {
  bucket = "kazu-input-bucket-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "kazu-input-bucket"
  }
}

# -----------------------------------------------
# S3バケット（出力）
# -----------------------------------------------
resource "aws_s3_bucket" "output" {
  bucket = "kazu-output-bucket-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "kazu-output-bucket"
  }
}

# AWSアカウントID取得
data "aws_caller_identity" "current" {}

# -----------------------------------------------
# SNSトピック
# -----------------------------------------------
resource "aws_sns_topic" "notify" {
  name = "kazu-image-notify"
}

# SNSメール購読
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.notify.arn
  protocol  = "email"
  endpoint  = "itpro.kazu@gmail.com"
}

# -----------------------------------------------
# Lambda用IAMロール
# -----------------------------------------------
resource "aws_iam_role" "lambda_role" {
  name = "kazu-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Lambda用ポリシー（S3・SNS・CloudWatchLogs）
resource "aws_iam_role_policy" "lambda_policy" {
  name = "kazu-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
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
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.notify.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------
# Lambda関数
# -----------------------------------------------
resource "aws_lambda_function" "image_resize" {
  filename      = "lambda_function.zip"
  function_name = "kazu-image-resize"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30

  # Pillowのlayer
  layers = ["arn:aws:lambda:ap-northeast-1:770693421928:layer:Klayers-p311-Pillow:10"]

  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.output.bucket
      SNS_TOPIC_ARN = aws_sns_topic.notify.arn
    }
  }

  tags = {
    Name = "kazu-image-resize"
  }
}

# LambdaへのS3トリガー許可
resource "aws_lambda_permission" "s3_trigger" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_resize.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.input.arn
}

# S3トリガー設定
resource "aws_s3_bucket_notification" "input_trigger" {
  bucket = aws_s3_bucket.input.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_resize.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3_trigger]
}