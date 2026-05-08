variable "env" {
  description = "環境名"
  type        = string
}

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
}

variable "kms_key_id" {
  description = "KMS Key ID for SecretsManager暗号化"
  type        = string
}