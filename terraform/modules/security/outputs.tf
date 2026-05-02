output "kms_key_arn" {
  description = "KMSキーARN"
  value       = aws_kms_key.main.arn
}

output "kms_key_id" {
  description = "KMSキーID"
  value       = aws_kms_key.main.key_id
}

output "db_secret_arn" {
  description = "Secrets ManagerのARN"
  value       = aws_secretsmanager_secret.db.arn
}