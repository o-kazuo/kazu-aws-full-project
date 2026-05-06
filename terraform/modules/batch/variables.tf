variable "env"             { type = string }
variable "aws_region"      { type = string }
variable "app_subnet_ids"  { type = list(string) }
variable "batch_sg_id"     { type = string }
variable "ecr_image_uri"   { type = string }