resource "aws_instance" "web" {
  ami           = "ami-00142334f8aedd43f"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_1a.id
  
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  depends_on = [aws_iam_instance_profile.ec2_profile]

  user_data = <<-EOF
#!/bin/bash
dnf update -y
dnf install -y httpd php php-mysqlnd
systemctl start httpd
systemctl enable httpd

# GitHubからmemo.phpをダウンロード
curl -o /var/www/html/memo.php https://raw.githubusercontent.com/o-kazuo/kazu-aws-full-project/main/app/memo.php

# RDSエンドポイントを環境変数として設定
echo "DB_HOST=${aws_db_instance.mysql.address}" >> /etc/environment

echo "<?php echo '<h1>Kazu PHP Server is Born!</h1>'; ?>" > /var/www/html/index.php
EOF

  tags = {
    Name = "kazu-EC2-web-server-1"
  }
}

# セキュリティグループ
resource "aws_security_group" "web_sg" {
  name        = "kazu-web-sg"
  description = "Allow HTTP inbound traffic"
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
    Name = "kazu-web-sg"
  }
}

output "web_public_ip" {
  value = aws_instance.web.public_ip
}