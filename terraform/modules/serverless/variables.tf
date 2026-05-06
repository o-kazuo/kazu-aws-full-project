variable "env" {
  description = "環境名"
  type        = string
}

variable "account_id" {
  description = "AWSアカウントID"
  type        = string
}

variable "kms_key_arn" {
  description = "KMSキーARN"
  type        = string
}

variable "notification_email" {
  description = "SNS通知先メールアドレス"
  type        = string
}

variable "lambda_zip_path" {
  description = "LambdaのZIPファイルパス"
  type        = string
}