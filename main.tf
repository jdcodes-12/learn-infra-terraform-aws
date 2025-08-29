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
  security_groups = [aws_security_group.instances.name]
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
  security_groups = [aws_security_group.instances.name]
  user_data       = <<-EOF
                    #!/bin/bash
                    echo "Hello from Instance 1" > index.html
                    python3 -m http.server 8080 &
                    EOF

  tags = {
    Name = "LearnInfra"
  }
}


data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name    = "vpc-id"
    values  = [data.aws_vpc.default.id]
  }
}

output "default_subnet_ids" {
  value     = data.aws_subnets.default.ids  
}

resource "aws_security_group" "instances" {
  name    = "instance-security-group"
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_inbound" {
  security_group_id     = aws_security_group.instances.id
  cidr_ipv4             = data.aws_vpc.default.cidr_block
  from_port             = 8080
  ip_protocol           = "tcp"
  to_port               = 8080
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id     = aws_security_group.instances.id
  cidr_ipv4             = "0.0.0.0/0"
  ip_protocol           = "-1" # all ports
}

# Setup Application Load Balancer

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type  = "text/plain"
      message_body  = "404: page not found"
      status_code   = 404
    }
  }
}

resource "aws_lb_target_group" "instances" {
  name      = "learn-infra-lb-target-group"
  port      = 8080
  protocol  = "HTTP"
  vpc_id    = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "learninfra-1" {
  target_group_arn  = aws_lb_target_group.instances.arn
  target_id         = aws_instance.learninfra-1.id
  port              = 8080
}

resource "aws_lb_target_group_attachment" "learninfra-2" {
  target_group_arn  = aws_lb_target_group.instances.arn
  target_id         = aws_instance.learninfra-2.id
  port              = 8080
}

resource "aws_lb_listener_rule" "instances" {
  listener_arn  = aws_lb_listener.http.arn
  priority      = 100

  condition {
    path_pattern {
      values    = ["*"]
    }
  }

  action {
    type              = "forward"
    target_group_arn  = aws_lb_target_group.instances.arn
  }
}

resource "aws_security_group" "app_lb" {
  name  = "app-lb-security-group"
}

resource "aws_security_group_rule" "allow_alb_http_inbound" {
  type                = "ingress" 
  security_group_id   = aws_security_group.app_lb.id

  from_port           = 8080
  protocol            = "tcp"
  to_port             = 8080
  cidr_blocks         = [data.aws_vpc.default.cidr_block]
}

resource "aws_security_group_rule" "allow_alb_http_outbound" {
  type                = "egress" 
  security_group_id   = aws_security_group.app_lb.id

  from_port           = 0
  protocol            = "tcp"
  to_port             = 0
  cidr_blocks         = ["0.0.0.0/0"]
}

resource "aws_lb" "app_lb" {
  name                = "web-app-load-balancer"
  load_balancer_type  = "application"
  subnets             = slice(data.aws_subnets.default.ids, 0, 2) # fist 2 subnets
  security_groups     = [aws_security_group.app_lb.id]
}

