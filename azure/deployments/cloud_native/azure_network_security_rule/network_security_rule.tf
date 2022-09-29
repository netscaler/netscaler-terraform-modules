resource "azurerm_network_security_rule" "example" {
  name                        = var.name
  priority                    = var.priority
  direction                   = var.direction
  access                      = var.access
  protocol                    = var.protocol
  source_port_range           = var.source_port_range
  destination_port_range      = var.destination_port_range
  source_address_prefixes     = var.source_address_prefixes
  destination_address_prefix  = var.destination_address_prefixes
  resource_group_name         = var.resource_group_name
  network_security_group_name = var.network_security_group_name
}

