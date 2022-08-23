output "azurerm_resource_group" {
  value = data.azurerm_resource_group.resource_group.name
}
output "azurerm_virtual_network" {
  value = data.azurerm_virtual_network.vnet.address_space
}
output "management_subnet" {
  value = "${data.azurerm_subnet.management_subnet.address_prefix}"
}
output "client_subnet" {
  value = "${data.azurerm_subnet.client_subnet.address_prefix}"
}
output "server_subnet" {
  value = "${data.azurerm_subnet.server_subnet.address_prefix}"
}


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