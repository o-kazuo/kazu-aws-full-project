variable "env" {
  description = "環境名"
  type        = string
}

variable "kms_key_arn" {
  description = "KMSキーARN"
  type        = string
}

variable "backup_resources" {
  description = "バックアップ対象リソースのARNリスト"
  type        = list(string)
}