output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "パブリックサブネットIDリスト"
  value       = [aws_subnet.public_1a.id, aws_subnet.public_1c.id]
}

output "app_subnet_ids" {
  description = "アプリ用プライベートサブネットIDリスト"
  value       = [aws_subnet.app_1a.id, aws_subnet.app_1c.id]
}

output "db_subnet_ids" {
  description = "DB用プライベートサブネットIDリスト"
  value       = [aws_subnet.db_1a.id, aws_subnet.db_1c.id]
}