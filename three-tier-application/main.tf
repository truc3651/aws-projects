provider "aws" {
  profile = var.profile
  region  = var.region
}

module "networking" {
    source = "./networking"
    vpc_cidr = "10.0.0.0/16"
    public_subnet_cidr = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnet_cidr = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
    database_subnet_cidr = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]
}

module "autoscaling" {
  source = "./autoscaling"
}