# IAM Role for EC2
resource "aws_iam_role" "ec2" {
  name = "${var.app_name}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# IAM Role Policy for EC2
resource "aws_iam_role_policy" "ec2" {
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["ecr:GetAuthorizationToken"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"],
        Resource = "arn:aws:ecr:${var.aws_region}:${var.aws_account_id}:repository/${var.app_name}"
      },
      {
        Effect = "Allow",
        Action = ["secretsmanager:GetSecretValue"],
        Resource = var.secret_arn
      },
      {
        Effect = "Allow",
        Action = ["s3:GetObject"],
        Resource = "arn:aws:s3:::${var.app_name}-static/*"
      },
      {
        Effect = "Allow",
        Action = ["rds:DescribeDBInstances"],
        Resource = "*"
      }
    ]
  })
}


# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.app_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# Launch Template
resource "aws_launch_template" "app" {
  name_prefix            = "${var.app_name}-"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  user_data              = base64encode(templatefile("${path.module}/../../user_data.sh", {
    ecr_repo_url = var.ecr_repo_url,
    image_tag    = var.image_tag,
    secret_arn   = var.secret_arn,
    aws_region   = var.aws_region,
    app_name     = var.app_name
  }))
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }
  vpc_security_group_ids = [var.ec2_sg_id]
  tags = {
    Name = "${var.app_name}-lt"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  desired_capacity    = var.asg_desired_capacity
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  vpc_zone_identifier = var.subnet_ids
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  target_group_arns = [var.target_group_arn]

  tag {
    key                 = "Name"
    value               = "${var.app_name}-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}
