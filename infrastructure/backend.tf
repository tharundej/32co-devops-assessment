terraform {
  backend "s3" {
    bucket = "terraform-bucket-test32"  # Replace with your actual unique name
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
