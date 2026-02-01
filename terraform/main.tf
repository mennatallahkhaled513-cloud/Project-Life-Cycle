# 1. Provider Configuration
provider "aws" {
  region = "us-east-1"
}

# 2. Data Source to fetch the latest Ubuntu 22.04 AMI
data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 3. Security Group (Updated to include Port 8080 for your Docker App)
resource "aws_security_group" "app_sg" {
  name        = "allow_web_traffic"
  description = "Allow SSH, HTTP, and App traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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
}

# 4. EC2 Instance Configuration
resource "aws_instance" "menna_ec2" {
  ami                    = data.aws_ami.latest_ubuntu.id # Dynamically fetched ID
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name               = "my-project-key" 

  tags = {
    Name = "Menna-App-Server"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -aG docker ubuntu
              EOF
}

# 5. Output the Public IP
output "ec2_public_ip" {
  value       = aws_instance.menna_ec2.public_ip
  description = "The public IP address of the EC2 instance"
}
