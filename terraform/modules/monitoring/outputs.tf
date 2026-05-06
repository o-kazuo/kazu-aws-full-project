output "dashboard_name" {
  description = "CloudWatchダッシュボード名"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "high_cpu_alarm_name" {
  description = "高CPUアラーム名"
  value       = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
}

output "alb_5xx_alarm_name" {
  description = "ALB 5XXエラーアラーム名"
  value       = aws_cloudwatch_metric_alarm.alb_5xx.alarm_name
}

output "guardduty_detector_id" {
  description = "GuardDuty Detector ID"
  value       = aws_guardduty_detector.main.id
}