resource "azurerm_route_table" "ha-openshift-route-table" {
  name                          = "ha-inc-openshift-rt"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = false
}

resource "azurerm_route" "route" {
  name                = format("route-%v", count.index)
  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.ha-openshift-route-table.name
  address_prefix      = element(var.openshift_route_address_prefixes,count.index)
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = lookup(var.openshift_route_addresses_details, element(var.openshift_route_address_prefixes,count.index), "what?")

  count = length(var.openshift_route_address_prefixes)

  depends_on = [
    azurerm_route_table.ha-openshift-route-table
  ]
}

resource "azurerm_subnet_route_table_association" "terraform-server-subnet-route-association" {
  subnet_id      = var.ha_server_subnet.id
  route_table_id = azurerm_route_table.ha-openshift-route-table.id

  depends_on = [
    azurerm_route_table.ha-openshift-route-table
  ]
}

resource "null_resource" "openshift_network_routes_in_ha" {
  connection {
    host = var.bastion_public_ip
    user = var.ubuntu_admin_user
    # Should be the private key corresponding to the one used for creating the ubuntu node
    private_key = file(var.ssh_private_key_file)
  }

  provisioner "remote-exec" {
    inline = [
      format("curl -s -k -H \"Content-Type: application/json\" -H \"X-NITRO-USER: %v\" -H \"X-NITRO-PASS: %v\" -d %#v https://%v/nitro/v1/config/route", var.adc_admin_username, var.adc_admin_password, jsonencode(
        {route={
          network=split("/",local.subnet_nsip_association[count.index].subnet_prefix)[0],
          netmask=cidrnetmask(local.subnet_nsip_association[count.index].subnet_prefix),
          gateway=cidrhost(var.ha_server_subnet.address_prefixes[0],1),
        }}
      ), local.subnet_nsip_association[count.index].nsip)
    ]
  }

  count = length(local.subnet_nsip_association)
}
