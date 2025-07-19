#!/bin/bash
yum update -y
yum install -y docker
service docker start
usermod -a -G docker ec2-user

# Authenticate to ECR
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_repo_url}

# Pull and run the Docker image
docker pull ${ecr_repo_url}:${image_tag}
docker run -d -p 3000:3000 \
  -e AWS_REGION=${aws_region} \
  -e SECRET_ARN=${secret_arn} \
  -e RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier ${app_name}-db --query 'DBInstances[0].Endpoint.Address' --output text) \
  --log-driver=awslogs \
  --log-opt awslogs-region=${aws_region} \
  --log-opt awslogs-group=/ecs/${app_name} \
  --log-opt awslogs-stream=$(curl -s http://169.254.169.254/latest/meta-data/instance-id) \
  ${ecr_repo_url}:${image_tag}
