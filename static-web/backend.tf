terraform {
  backend "s3" {
    bucket          = var.terraform_state_bucket
    key             = "static-web.tfstate"
    region          = var.region
    profile         = var.profile
    dynamodb_table  = "terraform-locks"
    encrypt         = true
  }
}