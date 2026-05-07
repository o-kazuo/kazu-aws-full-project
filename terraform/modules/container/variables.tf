variable "env" {
  description = "環境名"
  type        = string
}

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "app_subnets" {
  description = "アプリ用プライベートサブネットIDリスト"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "ALBセキュリティグループID"
  type        = string
}

variable "target_group_arn" {
  description = "ALBターゲットグループARN"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECRリポジトリURL"
  type        = string
}

variable "lex_bot_id" {
  description = "Lex v2 Bot ID"
  type        = string
}

variable "lex_bot_alias_id" {
  description = "Lex v2 Bot Alias ID"
  type        = string
}
variable "db_secret_arn" {
  description = "SecretsManager DB Secret ARN"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS Key ARN"
  type        = string
}

variable "db_sg_id" {
  description = "RDS DBセキュリティグループID"
  type        = string
}

variable "rds_proxy_sg_id" {
  description = "RDS ProxyセキュリティグループID"
  type        = string
}
