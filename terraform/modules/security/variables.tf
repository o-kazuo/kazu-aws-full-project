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