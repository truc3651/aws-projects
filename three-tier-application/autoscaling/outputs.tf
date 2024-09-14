
output "backend_alb_dns_name" {
  value = aws_lb.backend_alb.dns_name
  description = "The DNS name of the backend Application Load Balancer"
}