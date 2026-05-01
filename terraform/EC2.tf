resource "aws_security_group" "web_sg" {
  name   = "kazu-web-sg"
  vpc_id = aws_vpc.main.id

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
}

resource "aws_instance" "web" {
  ami           = "ami-09d28faae2d982116"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_1a.id

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Kazu's Server is Born!</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "kazu-EC2-web-server-1"
  }
}

output "web_public_ip" {
  value = aws_instance.web.public_ip
}
