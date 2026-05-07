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

output "ec2_role_name" {
  description = "EC2 IAMロール名"
  value       = aws_iam_role.ec2.name
}

output "batch_sg_id" { value = aws_security_group.batch.id }
output "github_actions_access_key_id" {
  description = "GitHub Actions用アクセスキーID"
  value       = aws_iam_access_key.github_actions.id
}

output "github_actions_secret_access_key" {
  description = "GitHub Actions用シークレットアクセスキー"
  value       = aws_iam_access_key.github_actions.secret
  sensitive   = true
}
