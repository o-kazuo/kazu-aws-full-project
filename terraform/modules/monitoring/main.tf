# 予算アラート
resource "aws_budgets_budget" "main" {
  name         = "${var.env}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
  }
}

# CloudWatch ダッシュボード
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.env}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "ALB Request Count"
          region = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "RequestCount"]
          ]
          period = 300
          stat   = "Sum"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "ALB 5XX Errors"
          region = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count"]
          ]
          period = 300
          stat   = "Sum"
        }
      }
    ]
  })
}

# CloudWatch アラーム（高CPU）
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.env}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU使用率が80%を超えました"
  alarm_actions       = [var.sns_topic_arn]

  tags = {
    Name = "${var.env}-high-cpu-alarm"
  }
}

# CloudWatch アラーム（ALB 5XXエラー）
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.env}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALBの5XXエラーが10件を超えました"
  alarm_actions       = [var.sns_topic_arn]

  tags = {
    Name = "${var.env}-alb-5xx-alarm"
  }
}

# GuardDuty
resource "aws_guardduty_detector" "main" {
  enable = true

  tags = {
    Name = "${var.env}-guardduty"
  }
}

# CloudWatch Logs グループ（アプリログ用）
resource "aws_cloudwatch_log_group" "app" {
  name              = "/app/${var.env}"
  retention_in_days = 30

  tags = {
    Name = "${var.env}-app-logs"
  }
}

# CloudWatch アラーム（Aurora DB接続数）
resource "aws_cloudwatch_metric_alarm" "db_connections" {
  alarm_name          = "${var.env}-db-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "DB接続数が80を超えました"
  alarm_actions       = [var.sns_topic_arn]

  tags = {
    Name = "${var.env}-db-connections-alarm"
  }
}

# CloudWatch アラーム（Lambda エラー）
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.env}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambdaエラーが5件を超えました"
  alarm_actions       = [var.sns_topic_arn]

  tags = {
    Name = "${var.env}-lambda-errors-alarm"
  }
}