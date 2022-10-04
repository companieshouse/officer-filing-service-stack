output "officer-filing-api-lb-listener-arn" {
  value = aws_lb_listener.admin-web-lb-listener.arn
}

output "officer-filing-api-lb-arn" {
  value = aws_lb.admin-web-lb.arn
}
