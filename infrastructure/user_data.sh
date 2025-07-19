#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Update and install Docker
yum update -y
yum install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Variables (ensure these are exported or passed into the script beforehand)
AWS_REGION="${aws_region}"
ECR_REPO_URL="${ecr_repo_url}"
IMAGE_TAG="${image_tag}"
SECRET_ARN="${secret_arn}"
APP_NAME="${app_name}"

# Authenticate Docker with ECR
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REPO_URL"

# Pull Docker image
docker pull "$ECR_REPO_URL:$IMAGE_TAG"

# Fetch RDS endpoint
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "${APP_NAME}-db" \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text \
  --region "$AWS_REGION")

# Run container
docker run -d -p 3000:3000 \
  -e AWS_REGION="$AWS_REGION" \
  -e SECRET_ARN="$SECRET_ARN" \
  -e RDS_ENDPOINT="$RDS_ENDPOINT" \
  --log-driver=awslogs \
  --log-opt awslogs-region="$AWS_REGION" \
  --log-opt awslogs-group="/ecs/${APP_NAME}" \
  "$ECR_REPO_URL:$IMAGE_TAG"
