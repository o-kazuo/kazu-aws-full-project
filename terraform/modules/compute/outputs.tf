output "alb_dns_name" {
  description = "ALBのDNS名"
  value       = aws_lb.web.dns_name
}

output "alb_arn" {
  description = "ALBのARN"
  value       = aws_lb.web.arn
}

output "web_sg_id" {
  description = "EC2セキュリティグループID"
  value       = aws_security_group.web.id
}

output "alb_sg_id" {
  description = "ALBセキュリティグループID"
  value       = aws_security_group.alb.id
}