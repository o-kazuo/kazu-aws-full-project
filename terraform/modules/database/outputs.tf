output "cluster_endpoint" {
  description = "Auroraクラスターエンドポイント"
  value       = aws_rds_cluster.main.endpoint
}

output "cluster_reader_endpoint" {
  description = "Auroraリーダーエンドポイント"
  value       = aws_rds_cluster.main.reader_endpoint
}

output "db_sg_id" {
  description = "DBセキュリティグループID"
  value       = aws_security_group.db.id
}

output "cluster_arn" {
  description = "AuroraクラスターARN"
  value       = aws_rds_cluster.main.arn
}

output "rds_proxy_endpoint" {
  description = "RDS Proxyエンドポイント"
  value       = aws_db_proxy.main.endpoint
}

output "rds_proxy_arn" {
  description = "RDS Proxy ARN"
  value       = aws_db_proxy.main.arn
}

# ===== DynamoDB =====

output "user_usage_table_arn" {
  description = "user_usageテーブルARN"
  value       = aws_dynamodb_table.user_usage.arn
}

output "processing_history_table_arn" {
  description = "processing_historyテーブルARN"
  value       = aws_dynamodb_table.processing_history.arn
}

output "chat_history_table_arn" {
  description = "chat_historyテーブルARN"
  value       = aws_dynamodb_table.chat_history.arn
}

output "macie_findings_table_arn" {
  description = "macie_findingsテーブルARN"
  value       = aws_dynamodb_table.macie_findings.arn
}
output "db_secret_arn" {
  description = "RDS Proxy用SecretARN"
  value       = aws_secretsmanager_secret.rds_proxy.arn
}

output "rds_proxy_sg_id" {
  description = "RDS ProxyセキュリティグループID"
  value       = aws_security_group.rds_proxy.id
}
