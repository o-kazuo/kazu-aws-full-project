output "cloudfront_domain_name" {
  description = "CloudFrontのドメイン名"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_id" {
  description = "CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "waf_arn" {
  description = "WAF WebACL ARN"
  value       = aws_wafv2_web_acl.main.arn
}