variable "env" {
  description = "環境名"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnets" {
  description = "パブリックサブネットIDリスト"
  type        = list(string)
}

variable "ami_id" {
  description = "EC2 AMI ID"
  type        = string
  default     = "ami-00142334f8aedd43f"
}

variable "instance_type" {
  description = "EC2インスタンスタイプ"
  type        = string
  default     = "t2.micro"
}

variable "ec2_role_name" {
  description = "EC2 IAMロール名"
  type        = string
}

variable "db_host" {
  description = "RDSエンドポイント"
  type        = string
}