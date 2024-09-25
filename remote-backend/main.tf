terraform { 
  cloud { 
    organization = "chiminhtao" 
    workspaces { 
      name = "my-workspace" 
    }
  } 

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.10.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_s3_bucket" "bucket" {
    bucket = "truc-nguyen-1811-test-bucket"
}

output "s3_bucket_bucket_domain_name" {
    value = aws_s3_bucket.bucket.bucket_domain_name
}