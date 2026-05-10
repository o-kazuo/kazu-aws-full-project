resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.env}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # ── 既存 ──────────────────────────────
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "ALB Request Count"
          region  = var.aws_region
          metrics = [["AWS/ApplicationELB", "RequestCount"]]
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "ALB 5XX Errors"
          region  = var.aws_region
          metrics = [["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count"]]
          period  = 300
          stat    = "Sum"
        }
      },

      # ── ECS ──────────────────────────────
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ECS CPU使用率"
          region = var.aws_region
          metrics = [[
            "AWS/ECS", "CPUUtilization",
            "ClusterName", "${var.env}-ecs-cluster",
            "ServiceName", "${var.env}-web-service"
          ]]
          period = 60
          stat   = "Average"
          annotations = {
            horizontal = [{ value = 70, label = "スケールアウト閾値", color = "#ff6961" }]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ECS メモリ使用率"
          region = var.aws_region
          metrics = [[
            "AWS/ECS", "MemoryUtilization",
            "ClusterName", "${var.env}-ecs-cluster",
            "ServiceName", "${var.env}-web-service"
          ]]
          period = 60
          stat   = "Average"
          annotations = {
            horizontal = [{ value = 80, label = "警告閾値", color = "#ff6961" }]
          }
        }
      },

      # ── RDS ──────────────────────────────
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 8
        height = 6
        properties = {
          title  = "RDS CPU使用率"
          region = var.aws_region
          metrics = [["AWS/RDS", "CPUUtilization"]]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 12
        width  = 8
        height = 6
        properties = {
          title  = "RDS 接続数"
          region = var.aws_region
          metrics = [["AWS/RDS", "DatabaseConnections"]]
          period = 300
          stat   = "Average"
          annotations = {
            horizontal = [{ value = 80, label = "警告閾値", color = "#ff6961" }]
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 12
        width  = 8
        height = 6
        properties = {
          title  = "RDS レイテンシ"
          region = var.aws_region
          metrics = [
            ["AWS/RDS", "ReadLatency"],
            ["AWS/RDS", "WriteLatency"]
          ]
          period = 300
          stat   = "Average"
        }
      },

      # ── Lambda ───────────────────────────
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 8
        height = 6
        properties = {
          title  = "Lambda エラー数"
          region = var.aws_region
          metrics = [[
            "AWS/Lambda", "Errors",
            "FunctionName", "${var.env}-image-resize"
          ]]
          period = 60
          stat   = "Sum"
          annotations = {
            horizontal = [{ value = 5, label = "アラーム閾値", color = "#ff6961" }]
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 18
        width  = 8
        height = 6
        properties = {
          title  = "Lambda 実行時間"
          region = var.aws_region
          metrics = [[
            "AWS/Lambda", "Duration",
            "FunctionName", "${var.env}-image-resize"
          ]]
          period = 60
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 18
        width  = 8
        height = 6
        properties = {
          title  = "Lambda 実行回数"
          region = var.aws_region
          metrics = [[
            "AWS/Lambda", "Invocations",
            "FunctionName", "${var.env}-image-resize"
          ]]
          period = 300
          stat   = "Sum"
        }
      },

      # ── CloudFront ────────────────────────
      {
        type   = "metric"
        x      = 0
        y      = 24
        width  = 12
        height = 6
        properties = {
          title  = "CloudFront キャッシュヒット率"
          region = "us-east-1"
          metrics = [["AWS/CloudFront", "CacheHitRate", "Region", "Global"]]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 24
        width  = 12
        height = 6
        properties = {
          title  = "CloudFront リクエスト数"
          region = "us-east-1"
          metrics = [["AWS/CloudFront", "Requests", "Region", "Global"]]
          period = 300
          stat   = "Sum"
        }
      },

      # ── WAF ──────────────────────────────
      {
        type   = "metric"
        x      = 0
        y      = 30
        width  = 12
        height = 6
        properties = {
          title  = "WAF ブロック数"
          region = var.aws_region
          metrics = [["AWS/WAFV2", "BlockedRequests"]]
          period = 300
          stat   = "Sum"
        }
      },

      # ── DynamoDB ─────────────────────────
      {
        type   = "metric"
        x      = 12
        y      = 30
        width  = 12
        height = 6
        properties = {
          title  = "DynamoDB 読み書きスロットリング"
          region = var.aws_region
          metrics = [
            ["AWS/DynamoDB", "ReadThrottleEvents",  "TableName", "${var.env}-image-analysis"],
            ["AWS/DynamoDB", "WriteThrottleEvents", "TableName", "${var.env}-image-analysis"]
          ]
          period = 300
          stat   = "Sum"
        }
      }
    ]
  })
}

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

# CloudWatch アラーム（高CPU）※EC2用・既存
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

# ECS CPU 70%超え → SNS通知
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_sns" {
  alarm_name          = "${var.env}-ecs-cpu-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "ECS CPU使用率が70%を超えました"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    ClusterName = "${var.env}-ecs-cluster"
    ServiceName = "${var.env}-web-service"
  }

  tags = { Name = "${var.env}-ecs-cpu-alert" }
}

# ECS メモリ 80%超え → SNS通知
resource "aws_cloudwatch_metric_alarm" "ecs_memory_sns" {
  alarm_name          = "${var.env}-ecs-memory-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS メモリ使用率が80%を超えました"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    ClusterName = "${var.env}-ecs-cluster"
    ServiceName = "${var.env}-web-service"
  }

  tags = { Name = "${var.env}-ecs-memory-alert" }
}