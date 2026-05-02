variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "env" {
  description = "環境名"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "パブリックサブネットCIDRリスト"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "app_subnets" {
  description = "アプリ用プライベートサブネットCIDRリスト"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "db_subnets" {
  description = "DB用プライベートサブネットCIDRリスト"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "cache_subnets" {
  description = "Cache用プライベートサブネットCIDRリスト"
  type        = list(string)
  default     = ["10.0.31.0/24", "10.0.32.0/24"]
}

variable "db_name" {
  description = "データベース名"
  type        = string
  default     = "kazudb"
}

variable "db_username" {
  description = "DBユーザー名"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "DBパスワード"
  type        = string
  sensitive   = true
}

variable "account_id" {
  description = "AWSアカウントID"
  type        = string
  default     = "227811178732"
}

variable "notification_email" {
  description = "通知先メールアドレス"
  type        = string
  default     = "itpro.kazu@gmail.com"
}

variable "lambda_zip_path" {
  description = "LambdaのZIPファイルパス"
  type        = string
  default     = "../../package/lambda_function.zip"
}