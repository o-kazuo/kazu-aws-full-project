variable "env" {
  description = "環境名"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "cache_subnets" {
  description = "Cache用サブネットIDリスト"
  type        = list(string)
}

variable "app_sg_ids" {
  description = "アプリ用セキュリティグループIDリスト"
  type        = list(string)
}