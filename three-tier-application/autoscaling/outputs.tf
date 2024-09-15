
output "alb_dns_name" {
  value = {
    backend = aws_lb.backend_alb.dns_name
    web = aws_lb.web_server_alb.dns_name
  }
}