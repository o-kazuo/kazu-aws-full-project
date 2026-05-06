variable "env" {
  description = "環境名"
  type        = string
}

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDRブロック"
  type        = string
}

variable "public_subnets" {
  description = "パブリックサブネットCIDRリスト"
  type        = list(string)
}

variable "app_subnets" {
  description = "アプリ用プライベートサブネットCIDRリスト"
  type        = list(string)
}

variable "db_subnets" {
  description = "DB用プライベートサブネットCIDRリスト"
  type        = list(string)
}

# （既存変数はそのまま）

# ===== ここから追加 =====

variable "cache_subnets" {
  description = "Cache用プライベートサブネットCIDRリスト"
  type        = list(string)
  default     = ["10.0.31.0/24", "10.0.32.0/24"]
}