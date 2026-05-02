variable "env" {
  description = "環境名"
  type        = string
}

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "app_subnets" {
  description = "アプリ用プライベートサブネットIDリスト"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "ALBセキュリティグループID"
  type        = string
}

variable "target_group_arn" {
  description = "ALBターゲットグループARN"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECRリポジトリURL"
  type        = string
  default     = "nginx"
}