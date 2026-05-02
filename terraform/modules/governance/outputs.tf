output "organization_id" {
  description = "AWS Organization ID"
  value       = aws_organizations_organization.main.id
}

output "dev_ou_id" {
  description = "開発OU ID"
  value       = aws_organizations_organizational_unit.dev.id
}

output "prod_ou_id" {
  description = "本番OU ID"
  value       = aws_organizations_organizational_unit.prod.id
}