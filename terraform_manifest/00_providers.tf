terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.97.0"
    }
  }
  backend "s3" {
    bucket  = "bucket-poc-zero"
    key     = "zero-terust-strategy/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
  }
}

provider "aws" {
  # Configuration options
  region = "ap-south-1"
}
