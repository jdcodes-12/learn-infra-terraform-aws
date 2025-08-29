# Note that this will use the `local` backend for Terraform State. This
# also means that there is not **locking**. This setup should only be used
# for learning purposes.

terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.11.0"
    }
  }
}

provider "aws" {
  region    = "us-east-1"
}

# EC2 Instance Setup

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name    = "name"
    values  = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name    = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name    = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "learninfra-1" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t3.micro"
  user_data       = <<-EOF
                    #!/bin/bash
                    echo "Hello from Instance 1" > index.html
                    python3 -m http.server 8080 &
                    EOF

  tags = {
    Name = "LearnInfra"
  }
}

resource "aws_instance" "learninfra-2" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t3.micro"
  user_data       = <<-EOF
                    #!/bin/bash
                    echo "Hello from Instance 1" > index.html
                    python3 -m http.server 8080 &
                    EOF

  tags = {
    Name = "LearnInfra"
  }
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-east-1a"

  tags = {
    Name = "Default subnet for us-east-1"
  }
}

resource "aws_default_vpc" "default_az1" {
  tags = {
    Name = "Default VPC for us-east-1"
  }
}

resource "aws_security_group" "instances" {
  name    = "instance-security-group"
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_inbound" {
  security_group_id     = aws_security_group.instances.id
  cidr_ipv4             = aws_default_vpc.default_az1.cidr_block
  from_port             = 8080
  ip_protocol           = "tcp"
  to_port               = 8080
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id     = aws_security_group.instances.id
  cidr_ipv4             = "0.0.0.0/0"
  ip_protocol           = "-1" # all ports
}
