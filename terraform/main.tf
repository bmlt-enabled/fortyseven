provider "aws" {
  region  = "us-east-1"
  profile = "mvana"
}

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.47"
    }
  }

  backend "s3" {
    bucket         = "mvana-account-terraform"
    region         = "us-east-1"
    profile        = "mvana"
    dynamodb_table = "mvana-account-terraform"
    key            = "fortysevenbot/terraform.tfstate"
  }
}

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["tomato"]
  }
}

data "aws_lb" "main" {
  name = "tomato"
}

data "aws_lb_listener" "main_443" {
  load_balancer_arn = data.aws_lb.main.arn
  port              = 443
}
