provider "aws" {
  region = "us-east-1"
}

# Data: Latest Ubuntu AMI
data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Security Group
resource "aws_security_group" "app_sg" {
  name        = "menna_app_sg_v5"
  description = "Allow SSH, HTTP, and Docker traffic"

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP Access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Docker App Port"
    from_port   = 8080
    to_port     = 8080
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
    Name = "Menna-App-SG"
  }
}

# EC2 Instance
resource "aws_instance" "menna_ec2" {
  ami           = data.aws_ami.latest_ubuntu.id
  instance_type = "t2.micro"
  key_name      = "ci_pem"   # <-- Correct key pair name
  security_groups = [aws_security_group.app_sg.name]

  tags = {
    Name = "Menna-App-Server"
  }

  user_data = <<-EOT
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ubuntu
  EOT
}

# Optional Output
output "ec2_public_ip" {
  value = aws_instance.menna_ec2.public_ip
}
