# 1. Provider Configuration
provider "aws" {
  region = "us-east-1" # Change this to your preferred region
}

# 2. Security Group (Opens SSH and HTTP ports)
resource "aws_security_group" "app_sg" {
  name        = "allow_web_traffic"
  description = "Allow SSH and HTTP inbound traffic"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
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

# 3. EC2 Instance Configuration
resource "aws_instance" "menna_ec2" {
  ami                    = "ami-0e2c8ccd4e0269736" # Standard Ubuntu 22.04 AMI for us-east-1
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  
  # IMPORTANT: Use your key name exactly as it appears in AWS Console
  key_name               = "my-project-key" 

  tags = {
    Name = "Menna-App-Server"
  }

  # This part ensures Docker is installed on the server automatically
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -aG docker ubuntu
              EOF
}

# 4. Outputs (GitHub Actions needs this to get the IP)
output "ec2_public_ip" {
  value       = aws_instance.menna_ec2.public_ip
  description = "The public IP address of the EC2 instance"
}
