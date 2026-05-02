terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "kazu-terraform-s3-bucket-227811178732"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "kazu-terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# ネットワーク層
module "networking" {
  source         = "../../modules/networking"
  env            = var.env
  aws_region     = var.aws_region
  vpc_cidr       = var.vpc_cidr
  public_subnets = var.public_subnets
  app_subnets    = var.app_subnets
  db_subnets     = var.db_subnets
}

# セキュリティ層
module "security" {
  source      = "../../modules/security"
  env         = var.env
  db_username = var.db_username
  db_password = var.db_password
}

# データベース層
module "database" {
  source      = "../../modules/database"
  env         = var.env
  vpc_id      = module.networking.vpc_id
  db_subnets  = module.networking.db_subnet_ids
  app_sg_ids  = [module.compute.web_sg_id]
  kms_key_arn = module.security.kms_key_arn
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}

# コンピュート層
module "compute" {
  source         = "../../modules/compute"
  env            = var.env
  vpc_id         = module.networking.vpc_id
  public_subnets = module.networking.public_subnet_ids
  ec2_role_name  = var.ec2_role_name
  db_host        = module.database.cluster_endpoint
}

# サーバーレス層
module "serverless" {
  source             = "../../modules/serverless"
  env                = var.env
  account_id         = var.account_id
  kms_key_arn        = module.security.kms_key_arn
  notification_email = var.notification_email
  lambda_zip_path    = var.lambda_zip_path
}

# 監視層
module "monitoring" {
  source             = "../../modules/monitoring"
  env                = var.env
  aws_region         = var.aws_region
  notification_email = var.notification_email
  sns_topic_arn      = module.serverless.sns_topic_arn
}
# バックアップ層
module "backup" {
  source      = "../../modules/backup"
  env         = var.env
  kms_key_arn = module.security.kms_key_arn
  backup_resources = [
    module.database.cluster_endpoint
  ]
}