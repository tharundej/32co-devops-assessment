# S3 Bucket
resource "aws_s3_bucket" "static" {
  bucket = "${var.app_name}-static"
  tags = {
    Name = "${var.app_name}-static"
  }
}