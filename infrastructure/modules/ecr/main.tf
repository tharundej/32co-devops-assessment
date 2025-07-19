# ECR Repository
resource "aws_ecr_repository" "app" {
  name = var.app_name
  tags = {
    Name = "${var.app_name}-ecr"
  }
}