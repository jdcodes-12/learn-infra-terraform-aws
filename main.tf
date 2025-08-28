# Note that this will use the `local` backend for Terraform State. This
# also means that there is not **locking**. This setup should only be used
# for learning purposes.

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami             = "ami-011899242bb902164" # Ubunutu 20.04 LTS //us-east 1
  instance_type   = "t3.micro"
}

## Remote Backend Bootstraping: Part 1 - local apply w/ requested resources.

# Versioned & encrypted S3 bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket          = "learn-iac-tf-state"
  force_destroy   = true
}

resource "aws_s3_bucket_acl" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  acl = "private"
}

resource "aws_s3_bucket_versioning" "versioning_terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id 

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.arn

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
  
# DynamoDB table used for terraform locking
resource "aws_dynamodb_table" "terraform_lock" {
  name          = "terraform-state-locking"
  billing_mode  = "PAY_PER_REQUEST"
  hash_key      = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

