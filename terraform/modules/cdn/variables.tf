variable "env" {
  description = "環境名"
  type        = string
}

variable "alb_dns_name" {
  description = "ALBのDNS名"
  type        = string
}
variable "s3_bucket_regional_domain_name" {
  description = "S3バケットのリージョナルドメイン名"
  type        = string
}

variable "s3_bucket_name" {
  description = "フロントエンドS3バケット名"
  type        = string
}

variable "s3_bucket_arn" {
  description = "フロントエンドS3バケットARN"
  type        = string
}
