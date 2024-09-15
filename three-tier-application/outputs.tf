output "alb_dns_name" {
  value = module.autoscaling.alb_dns_name
}

output "db" {
  value = module.database.db
}