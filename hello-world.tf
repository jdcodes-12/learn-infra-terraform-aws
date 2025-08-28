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

