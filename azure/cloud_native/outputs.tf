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

output "alb_public_ip" {
  value = azurerm_public_ip.terraform-load-balancer-public-ip.ip_address
}

output "cic_nsip" {
  value = module.azure_ilb_nsip
}

output "openshift_resource_group" {
  value = var.create_ha_for_openshift ? data.azurerm_virtual_network.openshift-vnet[0].resource_group_name : null
}

output "openshift_vnet_name" {
  value = var.create_ha_for_openshift ? data.azurerm_virtual_network.openshift-vnet[0].name : null
}

output "openshift_worker_subnet" {
  value = var.create_ha_for_openshift ? data.azurerm_subnet.openshift-worker-subnet[0].name : null
}

output "openshift_master_subnet" {
  value = var.create_ha_for_openshift ? data.azurerm_subnet.openshift-master-subnet[0].name : null
}

output "ha_route_table_id" {
  value = var.create_ha_for_openshift ? module.ha_openshift_route_table[0].route_table_id : null
}
