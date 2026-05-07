output "batch_job_queue_name"     { value = module.batch.job_queue_name }
output "batch_job_definition_name" { value = module.batch.job_definition_name }
output "lex_bot_id"               { value = module.lex.bot_id }
output "lex_bot_alias_id"         { value = module.lex.bot_alias_id }
output "github_actions_access_key_id" {
  description = "GitHub Actions用アクセスキーID"
  value       = module.security.github_actions_access_key_id
}

output "github_actions_secret_access_key" {
  description = "GitHub Actions用シークレットアクセスキー"
  value       = module.security.github_actions_secret_access_key
  sensitive   = true
}

output "cloudfront_domain_name" {
  description = "CloudFrontのドメイン名"
  value       = module.cdn.cloudfront_domain_name
}
