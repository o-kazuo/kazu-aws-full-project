# 起動テンプレート（Auto Scalingの設計図）
resource "aws_launch_template" "web" {
  name_prefix   = "kazu-web-"
  image_id        = "ami-00142334f8aedd43f"
  instance_type = "t2.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
dnf update -y
dnf install -y httpd php php-mysqlnd mariadb105
systemctl start httpd
systemctl enable httpd

# GitHubからmemo.phpをダウンロード
curl -o /var/www/html/memo.php https://raw.githubusercontent.com/o-kazuo/kazu-aws-full-project/main/app/memo.php

# RDSエンドポイントをApacheの環境変数として設定
echo "SetEnv DB_HOST ${aws_db_instance.mysql.address}" >> /etc/httpd/conf/httpd.conf

# Apacheを再起動して設定を反映
systemctl restart httpd

echo "<?php echo '<h1>Kazu PHP Server is Born!</h1>'; ?>" > /var/www/html/index.php
EOF
  )

  depends_on = [aws_iam_instance_profile.ec2_profile]

  tags = {
    Name = "kazu-web-launch-template"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name                = "kazu-web-asg"
  vpc_zone_identifier = [aws_subnet.public_1a.id, aws_subnet.public_1c.id]
  target_group_arns   = [aws_lb_target_group.web.arn]
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "kazu-web-asg-instance"
    propagate_at_launch = true
  }
}

# ALB用セキュリティグループ
resource "aws_security_group" "alb_sg" {
  name        = "kazu-alb-sg"
  description = "Allow HTTP inbound traffic to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "kazu-alb-sg"
  }
}

# EC2用セキュリティグループ（ALBからのみ受け付ける）
resource "aws_security_group" "web_sg" {
  name        = "kazu-web-sg"
  description = "Allow HTTP inbound traffic" #元に戻す
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kazu-web-sg"
  }
}

# ALB本体
resource "aws_lb" "web" {
  name               = "kazu-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1a.id, aws_subnet.public_1c.id]

  tags = {
    Name = "kazu-web-alb"
  }
}

# ターゲットグループ（ALBがEC2に転送する設定）
resource "aws_lb_target_group" "web" {
  name     = "kazu-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }

  tags = {
    Name = "kazu-web-tg"
  }
}

# ALBリスナー（80番ポートを受け付けてターゲットグループに転送）
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ALBのDNS名を出力
output "alb_dns_name" {
  value = aws_lb.web.dns_name
}