# SQSキュー
resource "aws_sqs_queue" "main" {
  name                      = "${var.env}-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  visibility_timeout_seconds = 30

  tags = {
    Name = "${var.env}-queue"
  }
}

# SQS デッドレターキュー
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.env}-dlq"
  message_retention_seconds = 604800

  tags = {
    Name = "${var.env}-dlq"
  }
}

# EventBridge ルール（スケジュール実行）
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${var.env}-schedule"
  description         = "定期実行スケジュール"
  schedule_expression = "rate(1 hour)"

  tags = {
    Name = "${var.env}-schedule"
  }
}

# EventBridge ターゲット（SQS）
resource "aws_cloudwatch_event_target" "sqs" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.main.arn
}

# SQSキューポリシー（EventBridgeからの送信許可）
resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.main.arn
    }]
  })
}