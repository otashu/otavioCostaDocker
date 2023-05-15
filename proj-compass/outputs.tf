//mostra o dns do lb ao terminar o apply
output "lb_dns" {
  value = aws_lb.ALB-compass.dns_name
}