# ===== AWS Batch =====

# IAM Role for Batch Execution
resource "aws_iam_role" "batch_execution_role" {
  name = "${var.env}-batch-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "batch.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "batch_service" {
  role       = aws_iam_role.batch_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# IAM Role for Job
resource "aws_iam_role" "batch_job_role" {
  name = "${var.env}-batch-job-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "batch_job_s3" {
  role       = aws_iam_role.batch_job_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "batch_job_ecr" {
  role       = aws_iam_role.batch_job_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM Role for ECS Task Execution（ECRからpullするために必要）
resource "aws_iam_role" "batch_task_execution_role" {
  name = "${var.env}-batch-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "batch_task_execution" {
  role       = aws_iam_role.batch_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Compute Environment（Fargate）
resource "aws_batch_compute_environment" "this" {
  compute_environment_name = "${var.env}-batch-compute"
  type                     = "MANAGED"
  service_role             = aws_iam_role.batch_execution_role.arn

  compute_resources {
    type               = "FARGATE"
    max_vcpus          = 4
    subnets            = var.app_subnet_ids
    security_group_ids = [var.batch_sg_id]
  }

  depends_on = [aws_iam_role_policy_attachment.batch_service]
}

# Job Queue
resource "aws_batch_job_queue" "this" {
  name     = "${var.env}-batch-queue"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.this.arn
  }
}

# Job Definition
resource "aws_batch_job_definition" "this" {
  name = "${var.env}-batch-job"
  type = "container"
  platform_capabilities = ["FARGATE"]

  container_properties = jsonencode({
    image            = var.ecr_image_uri
    jobRoleArn       = aws_iam_role.batch_job_role.arn
    executionRoleArn = aws_iam_role.batch_task_execution_role.arn

    resourceRequirements = [
      { type = "VCPU",   value = "0.5" },
      { type = "MEMORY", value = "1024" }
    ]

    networkConfiguration = {
      assignPublicIp = "DISABLED"
    }

    environment = [
      { name = "ENV",        value = var.env },
      { name = "AWS_REGION", value = var.aws_region }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/aws/batch/${var.env}-batch-job"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "batch"
      }
    }
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "batch" {
  name              = "/aws/batch/${var.env}-batch-job"
  retention_in_days = 7
}