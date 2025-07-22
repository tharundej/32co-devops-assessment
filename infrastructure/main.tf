# Configure the AWS provider
provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source          = "./modules/vpc"
  app_name        = var.app_name
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

# Security Groups Module
module "security_groups" {
  source   = "./modules/security_groups"
  app_name = var.app_name
  vpc_id   = module.vpc.vpc_id
}

# RDS Module
module "rds" {
  source           = "./modules/rds"
  app_name         = var.app_name
  subnet_ids       = module.vpc.private_subnet_ids
  rds_sg_id        = module.security_groups.rds_sg_id
  db_password      = random_password.db_password.result
}

# S3 Module
module "s3" {
  source   = "./modules/s3"
  app_name = var.app_name
}

# ECR Module
module "ecr" {
  source   = "./modules/ecr"
  app_name = var.app_name
}

# Secrets Manager Module
module "secrets" {
  source      = "./modules/secrets"
  app_name    = var.app_name
  db_password = random_password.db_password.result
}

# EC2 and Auto Scaling Module
data "aws_caller_identity" "current" {}
module "ec2" {
  source            = "./modules/ec2"
  environment       = var.environment
  aws_account_id = data.aws_caller_identity.current.account_id
  app_name          = var.app_name
  ami_id            = data.aws_ami.amazon_linux.id
  instance_type     = var.instance_type
  subnet_ids        = module.vpc.private_subnet_ids
  ec2_sg_id         = module.security_groups.ec2_sg_id
  target_group_arn  = module.alb.target_group_arn
  ecr_repo_url      = module.ecr.repository_url
  image_tag         = var.image_tag
  secret_arn        = module.secrets.secret_arn
  rds_endpoint      = module.rds.rds_endpoint 
  aws_region        = var.aws_region
  asg_min_size      = var.asg_min_size
  asg_max_size      = var.asg_max_size
  asg_desired_capacity = var.asg_desired_capacity
}

# Application Load Balancer Module
module "alb" {
  source     = "./modules/alb"
  app_name   = var.app_name
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id  = module.security_groups.alb_sg_id
}

# Monitoring Module
module "monitoring" {
  source             = "./modules/monitoring"
  app_name           = var.app_name
  alb_arn_suffix     = module.alb.alb_arn_suffix
  asg_name           = module.ec2.asg_name
  high_cpu_threshold = var.high_cpu_threshold
  low_cpu_threshold  = var.low_cpu_threshold
}

# Random Password for RDS
resource "random_password" "db_password" {
  length  = 16
  special = false
}

# Data Source for AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
