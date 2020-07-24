output "public_nsips" {
  value = azurerm_public_ip.terraform-adc-management-public-ip.*.ip_address
}

output "private_nsips" {
  value = azurerm_network_interface.terraform-adc-management-interface.*.private_ip_address
}

output "private_vips" {
  value = azurerm_network_interface.terraform-adc-client-interface.*.private_ip_address
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

output "availability_set_id" {
  value = azurerm_availability_set.terraform-availability-set.id
}

output "alb_public_ip" {
  value = azurerm_public_ip.terraform-load-balancer-public-ip.ip_address
}
