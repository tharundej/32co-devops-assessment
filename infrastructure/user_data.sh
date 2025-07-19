#!/bin/bash
# Update and install Docker
yum update -y
yum install -y docker jq
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Authenticate to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${ecr_repo_url}

# Retrieve secrets from AWS Secrets Manager
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id arn:aws:secretsmanager:us-west-2:038462786482:secret:devops-assessment-secrets-S5b00i --region us-west-2 --query SecretString --output text)
if [ $? -ne 0 ]; then
  echo "Error: Failed to retrieve secret" >> /var/log/userdata.log
  exit 1
fi

# Parse API key and database password
API_KEY=$(echo $SECRET_JSON | jq -r '.API_KEY')
DB_PASSWORD=$(echo $SECRET_JSON | jq -r '.DB_PASSWORD')
if [ -z "$API_KEY" ] || [ -z "$DB_PASSWORD" ]; then
  echo "Error: Failed to parse API_KEY or DB_PASSWORD" >> /var/log/userdata.log
  exit 1
fi

# Get RDS endpoint
RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier ${app_name}-db --region us-west-2 --query 'DBInstances[0].Endpoint.Address' --output text)
if [ $? -ne 0 ]; then
  echo "Error: Failed to retrieve RDS endpoint" >> /var/log/userdata.log
  exit 1
fi

# Pull and run the Docker image
docker pull ${ecr_repo_url}:${image_tag}
if [ $? -ne 0 ]; then
  echo "Error: Failed to pull Docker image" >> /var/log/userdata.log
  exit 1
fi

docker run -d -p 3000:3000 \
  -e AWS_REGION=us-west-2 \
  -e API_KEY="$API_KEY" \
  -e DB_PASSWORD="$DB_PASSWORD" \
  -e RDS_ENDPOINT="$RDS_ENDPOINT" \
  --log-driver=awslogs \
  --log-opt awslogs-region=us-west-2 \
  --log-opt awslogs-group=/ecs/${app_name} \
  --log-opt awslogs-stream=$(curl -s http://169.254.169.254/latest/meta-data/instance-id) \
  ${ecr_repo_url}:${image_tag}

if [ $? -ne 0 ]; then
  echo "Error: Failed to run Docker container" >> /var/log/userdata.log
  exit 1
fi
