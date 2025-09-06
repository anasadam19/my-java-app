provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "my_repo" {
  name = "my-app-repo"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI (update for your region)
  instance_type = "t2.micro"
  key_name      = "your-key-pair"  # Replace with your AWS key pair name

  security_group_ids = [aws_security_group.app_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install docker -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              EOF

  tags = {
    Name = "AppServer"
  }
}

resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict in production
  }

  ingress {
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

output "instance_public_ip" {
  value = aws_instance.app_server.public_ip
}

output "ecr_repo_url" {
  value = aws_ecr_repository.my_repo.repository_url
}