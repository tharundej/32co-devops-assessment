terraform {
  backend "s3" {
    bucket = "tfstate-32co-20250719"  # Replace with your actual unique name
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}
