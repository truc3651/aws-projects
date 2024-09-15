provider "aws" {
  profile = var.profile
  region  = var.region
}

module "networking" {
    source = "./networking"
    vpc_cidr = "10.0.0.0/16"
    azs = ["ap-southeast-1a", "ap-southeast-1b"]
    public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
    database_subnet_cidrs = ["10.0.5.0/24", "10.0.6.0/24"]
    my_ip = "113.23.111.125"
}

module "autoscaling" {
  source = "./autoscaling"
  vpc = module.networking.vpc
  sg = module.networking.sg
  subnets = module.networking.subnets
  key_pair_name = "deployer-key"
  hosted_zone_name = "trucstaticsite.io.vn"
  web_server_dns_name = "app.trucstaticsite.io.vn"
}

module "database" {
  source = "./database"
  database_subnet = module.networking.subnets.database
  database_sg = module.networking.sg.database_sg
  db_name = "mydb"
  username = "admin"
}