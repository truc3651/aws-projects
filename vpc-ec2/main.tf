provider "aws" {
  profile = var.profile
  region  = var.region
}

module "vpc" {
  source              = "./vpc"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.2.0/24", "10.0.4.0/24"]
  availability_zone   = ["ap-southeast-1a", "ap-southeast-1b"]
}

module "ec2" {
  source    = "./ec2"
  subnet_id = module.vpc.public_subnets[0].id
  vpc_id    = module.vpc.vpc_id
}


