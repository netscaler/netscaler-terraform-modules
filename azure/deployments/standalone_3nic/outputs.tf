output "public_nsip" {
  value = azurerm_public_ip.terraform-adc-management-public-ip.ip_address
}

output "private_nsip" {
  value = azurerm_network_interface.terraform-adc-management-interface.private_ip_address
}

output "public_vip" {
  value = azurerm_public_ip.terraform-adc-client-public-ip.ip_address
}

output "private_vip" {
  value = azurerm_network_interface.terraform-adc-client-interface.private_ip_address
}

output "server_subnet_id" {
  value = azurerm_subnet.terraform-server-subnet.id
}

output "management_subnet_id" {
  value = azurerm_subnet.terraform-management-subnet.id
}

output "bastion_public_ip" {
  value = azurerm_public_ip.terraform-ubuntu-public-ip.ip_address
}
