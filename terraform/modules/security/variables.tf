variable "env" {
  description = "環境名"
  type        = string
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

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}


variable "db_endpoint" {
  description = "RDS ProxyのWriterエンドポイント"
  type        = string
  default     = ""
}

variable "db_name" {
  description = "DB名"
  type        = string
  default     = "kazudb"
}

variable "db_secret_arn" {
  description = "RDS Proxy用SecretARN（databaseモジュールから）"
  type        = string
  default     = ""
}

variable "account_id" {
  description = "AWSアカウントID"
  type        = string
}

variable "rds_proxy_endpoint" {
  description = "RDS Proxy Writerエンドポイント"
  type        = string
  default     = ""
}

variable "rds_proxy_reader_endpoint" {
  description = "RDS Proxy Readerエンドポイント"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}