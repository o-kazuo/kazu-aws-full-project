output "redis_endpoint" {
  description = "Redisプライマリエンドポイント"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "Redisリーダーエンドポイント"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "redis_port" {
  description = "Redisポート番号"
  value       = aws_elasticache_replication_group.main.port
}

output "cache_sg_id" {
  description = "CacheセキュリティグループID"
  value       = aws_security_group.cache.id
}