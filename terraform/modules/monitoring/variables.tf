variable "env" {
  description = "環境名"
  type        = string
}

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
}

variable "budget_limit" {
  description = "月次予算上限（USD）"
  type        = string
  default     = "10"
}

variable "notification_email" {
  description = "通知先メールアドレス"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNSトピックARN"
  type        = string
}