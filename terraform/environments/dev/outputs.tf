output "batch_job_queue_name"     { value = module.batch.job_queue_name }
output "batch_job_definition_name" { value = module.batch.job_definition_name }
output "lex_bot_id"               { value = module.lex.bot_id }
output "lex_bot_alias_id"         { value = module.lex.bot_alias_id }
output "github_actions_role_arn" {
  description = "GitHub Actions用IAMロールARN"
  value       = module.security.github_actions_role_arn
}

output "cloudfront_domain_name" {
  description = "CloudFrontのドメイン名"
  value       = module.cdn.cloudfront_domain_name
}
