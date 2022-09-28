output "private_backend_management_ips" {
  value = azurerm_network_interface.terraform-ubuntu-management-interface.*.private_ip_address
}

output "public_backend_management_ips" {
  value = azurerm_public_ip.terraform-ubuntu-public-ip.*.ip_address
}

output "backend_server_ips" {
  value = azurerm_network_interface.terraform-ubuntu-server-interface.*.private_ip_address
}
