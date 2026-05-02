# DBサブネットグループ
resource "aws_db_subnet_group" "main" {
  name       = "${var.env}-db-subnet-group"
  subnet_ids = var.db_subnets

  tags = {
    Name = "${var.env}-db-subnet-group"
  }
}

# DB用セキュリティグループ
resource "aws_security_group" "db" {
  name        = "${var.env}-db-sg"
  description = "Database security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = var.app_sg_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-db-sg"
  }
}

# Aurora Serverless v2 クラスター
resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${var.env}-aurora-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.05.2"
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  kms_key_id              = var.kms_key_arn
  storage_encrypted       = true
  skip_final_snapshot     = true
  deletion_protection     = false

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 4.0
  }

  tags = {
    Name = "${var.env}-aurora-cluster"
  }
}

# Aurora Serverless v2 インスタンス
resource "aws_rds_cluster_instance" "main" {
  identifier         = "${var.env}-aurora-instance-1"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  tags = {
    Name = "${var.env}-aurora-instance-1"
  }
}