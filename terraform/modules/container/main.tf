# ECRリポジトリ
resource "aws_ecr_repository" "main" {
  name                 = "${var.env}-web-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.env}-web-app"
  }
}

# ECSクラスター
resource "aws_ecs_cluster" "main" {
  name = "${var.env}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.env}-ecs-cluster"
  }
}

# ECS用セキュリティグループ
resource "aws_security_group" "ecs" {
  name        = "${var.env}-ecs-sg"
  description = "ECS Fargate security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  tags = {
    Name = "${var.env}-ecs-sg"
  }
}

# ECS タスクロール（コンテナが使うロール）
resource "aws_iam_role" "ecs_task" {
  name = "${var.env}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = {
    Name = "${var.env}-ecs-task-role"
  }
}

# ECS タスクロールにSSMアクセス権限（execute-command用）
resource "aws_iam_role_policy_attachment" "ecs_task_ssm" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ECS Task Definition用IAMロール
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.env}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = {
    Name = "${var.env}-ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# SecretsManager & KMSアクセス権限
resource "aws_iam_role_policy" "ecs_secrets" {
  name = "${var.env}-ecs-secrets-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.db_secret_arn
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = var.kms_key_arn
      }
    ]
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.env}-web-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = "web"
    image     = "${var.ecr_repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]
    environment = [
      { name = "AWS_REGION",           value = var.aws_region },
      { name = "LEX_BOT_ID",           value = var.lex_bot_id },
      { name = "LEX_BOT_ALIAS_ID",     value = var.lex_bot_alias_id },
      { name = "BATCH_JOB_QUEUE",      value = "dev-batch-queue" },
      { name = "BATCH_JOB_DEFINITION", value = "dev-batch-job" }
    ],
    secrets = [
      {
        name      = "DATABASE_URL"
        valueFrom = "${var.db_secret_arn}:DATABASE_URL::"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.env}-web"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name = "${var.env}-web-task"
  }
}

# CloudWatch Logsグループ
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.env}-web"
  retention_in_days = 7

  tags = {
    Name = "${var.env}-ecs-logs"
  }
}

# ECS→RDS SGルール（3306ポート）
resource "aws_security_group_rule" "ecs_to_rds_proxy" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = var.rds_proxy_sg_id
  security_group_id        = aws_security_group.ecs.id
  description              = "ECS to RDS Proxy 3306"
}

resource "aws_security_group_rule" "rds_proxy_from_ecs" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
  security_group_id        = var.rds_proxy_sg_id
  description              = "RDS Proxy from ECS 3306"
}

# ECS Service
resource "aws_ecs_service" "main" {
  name                   = "${var.env}-web-service"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.main.arn
  desired_count          = 1
  launch_type            = "FARGATE"

  network_configuration {
    subnets          = var.app_subnets
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "web"
    container_port   = 80
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution]

  tags = {
    Name = "${var.env}-web-service"
  }
}

# ECSの全アウトバウンド通信許可
resource "aws_security_group_rule" "ecs_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs.id
  description       = "ECS outbound all"
}