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