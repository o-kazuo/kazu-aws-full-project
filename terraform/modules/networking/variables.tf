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