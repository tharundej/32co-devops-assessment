#!/bin/bash
set -xe

# Update and install docker & aws-cli
yum update -y
yum install -y docker aws-cli
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group (may require user login to take effect)
usermod -aG docker ec2-user

# Wait for docker daemon ready
until systemctl is-active docker; do
  echo "Waiting for docker daemon..."
  sleep 10
done

# Login to ECR with retries
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_repo_url}

# Pull image
docker pull ${ecr_repo_url}:${image_tag}

# Wait for network connectivity and RDS availability if needed

# Run container
docker run -d -p 3000:3000 \
  -e AWS_REGION=${aws_region} \
  -e SECRETS_ARN=${secret_arn} \
  -e RDS_ENDPOINT=${rds_endpoint} \
  ${ecr_repo_url}:${image_tag}

# Optional: redirect logs somewhere for debugging
