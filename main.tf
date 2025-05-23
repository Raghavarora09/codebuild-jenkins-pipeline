# Variables
variable "aws_region" {
  description = "The AWS region to deploy to"
  default     = "ap-south-1"
}

variable "aws_access_key" {
  description = "AWS access key"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair to use"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for the first public subnet"
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for the second public subnet"
  default     = "10.0.2.0/24"
}

# Provider configuration
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Subnets
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Security Group for Jenkins
resource "aws_security_group" "jenkins" {
  name        = "jenkins-sg"
  description = "Security group for Jenkins server"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

  tags = {
    Name = "jenkins-sg"
  }
}

# Security Group for Web Servers
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "web-sg"
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "codedeploy_ec2_role" {
  name = "codedeploy-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach necessary policies to the role
resource "aws_iam_role_policy_attachment" "codedeploy_ec2_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
  role       = aws_iam_role.codedeploy_ec2_role.name
}

# Create an instance profile
resource "aws_iam_instance_profile" "codedeploy_ec2_profile" {
  name = "codedeploy-ec2-profile"
  role = aws_iam_role.codedeploy_ec2_role.name
}

# Jenkins EC2 Instance
resource "aws_instance" "jenkins" {
  ami                    = "ami-0522ab6e1ddcc7055"  # Ubuntu AMI for ap-south-1
  instance_type          = "t2.medium"
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  subnet_id              = aws_subnet.public_1.id
  iam_instance_profile   = aws_iam_instance_profile.codedeploy_ec2_profile.name

  tags = {
    Name = "jenkins-server"
  }
user_data = <<-EOF
              #!/bin/bash
              # Update and install dependencies
              sudo apt update -y
              sudo apt install -y openjdk-17-jdk curl gnupg2 unzip

              # Add Jenkins repository and key (updated for 2024+)
              curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
                /usr/share/keyrings/jenkins-keyring.asc > /dev/null

              echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
                https://pkg.jenkins.io/debian binary/ | sudo tee \
                /etc/apt/sources.list.d/jenkins.list > /dev/null

              # Install Jenkins
              sudo apt update -y
              sudo apt install -y jenkins
              sudo systemctl start jenkins
              sudo systemctl enable jenkins

              # Install AWS CLI
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install

              # Update PATH for AWS CLI
              export PATH=$PATH:/usr/local/bin
              echo 'export PATH=$PATH:/usr/local/bin' | sudo tee -a /etc/profile
              source /etc/profile

              EOF
}

# Launch Template for Web Servers
resource "aws_launch_template" "web" {
  name_prefix   = "web-"
  image_id      = "ami-0522ab6e1ddcc7055"  # Ubuntu AMI for ap-south-1
  instance_type = "t2.medium"
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.web.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.codedeploy_ec2_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "web-server"
    }
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apache2
              systemctl start apache2
              systemctl enable apache2
              apt-get install -y ruby wget
              cd /home/ubuntu
              wget https://aws-codedeploy-${var.aws_region}.s3.amazonaws.com/latest/install
              chmod +x ./install
              ./install auto
              EOF
  )
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  desired_capacity    = 2
  max_size            = 5
  min_size            = 1
  target_group_arns   = [aws_lb_target_group.web.arn]
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "web-server"
    propagate_at_launch = true
  }
}

# Application Load Balancer
resource "aws_lb" "web" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "web-alb"
  }
}

# ALB Target Group
resource "aws_lb_target_group" "web" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

# ALB Listener
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# CodeDeploy Application
resource "aws_codedeploy_app" "web" {
  compute_platform = "Server"
  name             = "web-app"
}

# CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "web" {
  app_name              = aws_codedeploy_app.web.name
  deployment_group_name = "web-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy.arn

  deployment_config_name = "CodeDeployDefault.OneAtATime"

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "web-server"
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}

# IAM Role for CodeDeploy
resource "aws_iam_role" "codedeploy" {
  name = "codedeploy-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AWS managed policy for CodeDeploy
resource "aws_iam_role_policy_attachment" "codedeploy_service" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy.name
}

# Output the ALB DNS name
output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.web.dns_name
}

# Output Jenkins server public IP
output "jenkins_public_ip" {
  description = "Public IP address of the Jenkins server"
  value       = aws_instance.jenkins.public_ip
}