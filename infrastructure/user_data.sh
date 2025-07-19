
#!/bin/bash
set -e  # Exit on error

# Install and configure Docker
yum update -y
yum install -y docker aws-cli
service docker start
chkconfig docker on
usermod -a -G docker ec2-user

# Authenticate to ECR
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_repo_url}

# Pull Docker image
docker pull ${ecr_repo_url}:${image_tag}

# Get RDS endpoint with error handling
RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier ${app_name}-db --region ${aws_region} --query 'DBInstances[0].Endpoint.Address' --output text 2>/dev/null) || {
  echo "Failed to get RDS endpoint" >&2
  exit 1
}

# Run Node.js app
docker run -d -p 3000:3000 \
  -e AWS_REGION=${aws_region} \
  -e SECRET_ARN=${secret_arn} \
  -e RDS_ENDPOINT=${RDS_ENDPOINT} \
  --log-driver=awslogs \
  --log-opt awslogs-region=${aws_region} \
  --log-opt awslogs-group=/ecs/${app_name} \
  --log-opt awslogs-create-group=true \
  ${ecr_repo_url}:${image_tag}
