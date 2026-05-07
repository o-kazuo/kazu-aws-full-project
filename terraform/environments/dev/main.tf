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

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# ネットワーク層 ← cache_subnets追加
module "networking" {
  source         = "../../modules/networking"
  env            = var.env
  aws_region     = var.aws_region
  vpc_cidr       = var.vpc_cidr
  public_subnets = var.public_subnets
  app_subnets    = var.app_subnets
  db_subnets     = var.db_subnets
  cache_subnets  = var.cache_subnets  # ← 追加
}

# データベース層 ← db_secret_arn追加
module "database" {
  source        = "../../modules/database"
  env           = var.env
  vpc_id        = module.networking.vpc_id
  db_subnets    = module.networking.db_subnet_ids
  app_sg_ids    = [module.compute.web_sg_id]
  kms_key_arn   = module.security.kms_key_arn
  db_name       = var.db_name
  db_username   = var.db_username
  db_password   = var.db_password
}

# セキュリティ層
module "security" {
  source        = "../../modules/security"
  env           = var.env
  db_username   = var.db_username
  db_password   = var.db_password
  vpc_id        = module.networking.vpc_id
  db_endpoint   = module.database.rds_proxy_endpoint
  db_name       = var.db_name
  db_secret_arn = module.database.db_secret_arn
  account_id    = var.account_id
}

# コンピュート層
module "compute" {
  source         = "../../modules/compute"
  env            = var.env
  vpc_id         = module.networking.vpc_id
  public_subnets = module.networking.public_subnet_ids
  ec2_role_name  = module.security.ec2_role_name
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
    module.database.cluster_arn
  ]
}

# CDN層
module "cdn" {
  source = "../../modules/cdn"
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
  env                            = var.env
  alb_dns_name                   = module.compute.alb_dns_name
  s3_bucket_regional_domain_name = module.serverless.frontend_bucket_regional_domain_name
  s3_bucket_name                 = module.serverless.frontend_bucket_name
  s3_bucket_arn                  = module.serverless.frontend_bucket_arn
}

# Lex
module "lex" {
  source = "../../modules/lex"
  env    = var.env
}

# コンテナ層
module "container" {
  source             = "../../modules/container"
  env                = var.env
  aws_region         = var.aws_region
  vpc_id             = module.networking.vpc_id
  app_subnets        = module.networking.app_subnet_ids
  alb_sg_id          = module.compute.alb_sg_id
  target_group_arn   = module.compute.ecs_target_group_arn
  ecr_repository_url = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.env}-web-app"
  lex_bot_id         = module.lex.bot_id        # ← 追加
  lex_bot_alias_id   = module.lex.bot_alias_id  # ← 追加
  db_secret_arn      = module.security.db_secret_arn
  kms_key_arn        = module.security.kms_key_arn
  db_sg_id           = module.database.db_sg_id
  rds_proxy_sg_id    = module.database.rds_proxy_sg_id
}

# 認証層
module "auth" {
  source     = "../../modules/auth"
  env        = var.env
  aws_region = var.aws_region
}

# メッセージング層
module "messaging" {
  source = "../../modules/messaging"
  env    = var.env
}

# ガバナンス層
module "governance" {
  source            = "../../modules/governance"
  env               = var.env
  cloudtrail_bucket = module.serverless.input_bucket_name
}

# ===== ここから追加 =====

# キャッシュ層
module "cache" {
  source        = "../../modules/cache"
  env           = var.env
  vpc_id        = module.networking.vpc_id
  cache_subnets = module.networking.cache_subnet_ids
  app_sg_ids    = [module.compute.web_sg_id]
}

module "batch" {
  source         = "../../modules/batch"
  env            = var.env
  aws_region     = var.aws_region
  app_subnet_ids = module.networking.app_subnet_ids
  batch_sg_id    = module.security.batch_sg_id
  ecr_image_uri  = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/dev-web-app:latest"
}
