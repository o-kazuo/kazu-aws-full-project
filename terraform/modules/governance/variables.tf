variable "env" {
  description = "環境名"
  type        = string
}

variable "cloudtrail_bucket" {
  description = "CloudTrailログ用S3バケット名"
  type        = string
}