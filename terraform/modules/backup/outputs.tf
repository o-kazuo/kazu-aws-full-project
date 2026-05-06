output "backup_vault_name" {
  description = "バックアップボールト名"
  value       = aws_backup_vault.main.name
}

output "backup_plan_id" {
  description = "バックアッププランID"
  value       = aws_backup_plan.main.id
}