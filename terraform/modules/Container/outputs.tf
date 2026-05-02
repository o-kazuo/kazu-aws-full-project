output "ecr_repository_url" {
  description = "ECRリポジトリURL"
  value       = aws_ecr_repository.main.repository_url
}

output "ecs_cluster_name" {
  description = "ECSクラスター名"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECSサービス名"
  value       = aws_ecs_service.main.name
}

output "ecs_sg_id" {
  description = "ECSセキュリティグループID"
  value       = aws_security_group.ecs.id
}