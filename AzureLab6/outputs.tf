output "load_balancer_ip" {
  value = azurerm_public_ip.lb_pip.ip_address
}

output "app_gateway_ip" {
  value = azurerm_public_ip.appgw_pip.ip_address
}