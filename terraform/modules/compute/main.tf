# ALB用セキュリティグループ
resource "aws_security_group" "alb" {
  name        = "${var.env}-alb-sg"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-alb-sg"
  }
}

# EC2用セキュリティグループ
resource "aws_security_group" "web" {
  name        = "${var.env}-web-sg"
  description = "Web server security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-web-sg"
  }
}

# ALB本体
resource "aws_lb" "web" {
  name               = "${var.env}-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets

  tags = {
    Name = "${var.env}-web-alb"
  }
}

# ターゲットグループ
resource "aws_lb_target_group" "web" {
  name        = "${var.env}-web-tg-ip"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }

  tags = {
    Name = "${var.env}-web-tg-ip"
  }
}

# ECS Fargate用ターゲットグループ（ip タイプ）
resource "aws_lb_target_group" "ecs" {
  name        = "${var.env}-ecs-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }

  tags = {
    Name = "${var.env}-ecs-tg"
  }
}

# ALBリスナー
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }
}

# IAMインスタンスプロファイル
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.env}-ec2-profile"
  role = var.ec2_role_name
}

# 起動テンプレート
resource "aws_launch_template" "web" {
  name_prefix   = "${var.env}-web-"

  image_id      = var.ami_id
  
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web.id]
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
dnf update -y
dnf install -y httpd php php-mysqlnd mariadb105
systemctl start httpd
systemctl enable httpd
curl -o /var/www/html/memo.php https://raw.githubusercontent.com/o-kazuo/kazu-aws-full-project/main/app/memo.php
echo "SetEnv DB_HOST ${var.db_host}" >> /etc/httpd/conf/httpd.conf
systemctl restart httpd
echo "<?php echo '<h1>Kazu PHP Server is Born!</h1>'; ?>" > /var/www/html/index.php
EOF
  )

  tags = {
    Name = "${var.env}-web-launch-template"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name                = "${var.env}-web-asg"
  vpc_zone_identifier = var.public_subnets
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.env}-web-asg-instance"
    propagate_at_launch = true
  }
}