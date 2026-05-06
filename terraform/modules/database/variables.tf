variable "env" {
  description = "環境名"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "db_subnets" {
  description = "DB用サブネットIDリスト"
  type        = list(string)
}

variable "app_sg_ids" {
  description = "アプリ用セキュリティグループIDリスト"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMSキーARN"
  type        = string
}

variable "db_name" {
  description = "データベース名"
  type        = string
  default     = "kazudb"
}

variable "db_username" {
  description = "DBユーザー名"
  type        = string
}

variable "db_password" {
  description = "DBパスワード"
  type        = string
  sensitive   = true
}

