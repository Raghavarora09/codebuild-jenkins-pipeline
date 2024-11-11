# AWS CodeBuild CI/CD

This project sets up a Jenkins-based CI/CD pipeline on AWS using Terraform and AWS CodeDeploy, enabling automatic deployment of a web application from GitHub upon each commit.

## Project Overview

The following infrastructure is created:

### 1. VPC (Virtual Private Cloud)
- `aws_vpc.main`: A VPC with CIDR block `10.0.0.0/16`, DNS support, and hostnames enabled.

### 2. Internet Gateway
- `aws_internet_gateway.main`: Provides internet access for resources in the VPC.

### 3. Subnets
- `aws_subnet.public_1` and `aws_subnet.public_2`: Public subnets in different availability zones with public IP auto-assignment.

### 4. Route Table
- `aws_route_table.public`: Routes all traffic to the Internet Gateway.
- `aws_route_table_association.public_1` and `aws_route_table_association.public_2`: Associates public subnets with the route table.

### 5. Security Groups
- `aws_security_group.jenkins`: Allows inbound SSH (port 22) and Jenkins (port 8080) traffic; all outbound traffic is permitted.
- `aws_security_group.web`: Allows inbound HTTP (port 80) and SSH (port 22) traffic; all outbound traffic is permitted.

### 6. IAM Roles and Instance Profiles
- `aws_iam_role.codedeploy_ec2_role`: EC2 role for CodeDeploy permissions.
- `aws_iam_role_policy_attachment.codedeploy_ec2_policy`: Attaches CodeDeploy permissions to EC2 role.
- `aws_iam_instance_profile.codedeploy_ec2_profile`: Attaches IAM role to EC2 instances.

### 7. Jenkins EC2 Instance
- `aws_instance.jenkins`: EC2 instance for Jenkins (t2.medium) with a user data script to install Jenkins, AWS CLI, and other dependencies.

### 8. Launch Template for Web Servers
- `aws_launch_template.web`: Template to create web server instances with an Ubuntu AMI and a script to install Apache and the CodeDeploy agent.

### 9. Auto Scaling Group
- `aws_autoscaling_group.web`: Auto Scaling Group for web servers with a desired capacity of 2 and a maximum of 5 instances across public subnets.

### 10. Application Load Balancer
- `aws_lb.web`: ALB to distribute traffic across web servers.
- `aws_lb_target_group.web`: Target group for ALB listening on port 80, with health checks on the root path.
- `aws_lb_listener.web`: ALB listener to forward traffic to the target group.

### 11. CodeDeploy Resources
- `aws_codedeploy_app.web`: CodeDeploy application for the web application.
- `aws_codedeploy_deployment_group.web`: Deployment group that targets EC2 instances by tags and supports rollback on failure.

### 12. IAM Role for CodeDeploy
- `aws_iam_role.codedeploy`: IAM role for CodeDeploy interaction with AWS services.
- `aws_iam_role_policy_attachment.codedeploy_service`: Managed policy for CodeDeploy permissions.

## Setup Instructions

### Step 1: Clone Repository
Clone the GitHub repository:
```bash
git clone https://github.com/Raghavarora09/task-pipeline.git
cd task-pipeline
```

### Step 2: Initialize and Apply Terraform
Initialize Terraform and apply the configuration:
```bash
terraform init
terraform apply
```

### Step 3: Set Up Jenkins
1. Use the administrator password from the Jenkins instance to unlock Jenkins.
2. Install the suggested plugins along with the required plugins for AWS and GitHub integration.
3. Restart Jenkins after plugin installation.

### Step 4: Configure AWS Credentials in Jenkins
1. Set up AWS credentials in Jenkins using the credentials provided in the `terraform.tfvars` file.
2. Copy the credentials ID and update it in the Jenkinsfile in the GitHub repository.

### Step 5: Create a New Pipeline in Jenkins
1. Go to Jenkins > New Item > Pipeline.
2. Select **GitHub hook trigger for GITScm polling**.
3. In the **Pipeline** section, select **Pipeline from SCM** and provide the GitHub repository URL.

### Step 6: Configure GitHub Webhook
1. Go to **GitHub > Settings > Webhooks > New Webhook**.
2. Set the payload URL to `<Jenkins_url>/github-webhook/`.

## Pipeline Operation
With this setup:
- Each commit to the GitHub repository will trigger a new Jenkins build.
- The application will be automatically deployed to the web server instances using AWS CodeDeploy.

## Dependencies
- Terraform
- AWS CLI
- Jenkins
- GitHub account with repository access

## License
This project is licensed under the MIT License.
