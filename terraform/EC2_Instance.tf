resource "aws_instance" "web" {
  ami           = "ami-00142334f8aedd43f"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_1a.id
  
  # ↓これを追加しました！これでネット上の住所（IP）が確定します
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
#!/bin/bash
dnf update -y
dnf install -y httpd php php-mysqlnd
systemctl start httpd
systemctl enable httpd
echo "<?php echo '<h1>Kazu PHP Server is Born!</h1>'; phpinfo(); ?>" > /var/www/html/index.php
EOF

  tags = {
    Name = "kazu-EC2-web-server-1"
  }
}

# セキュリティグループとOutputの設定（下にあるはずのもの）
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
