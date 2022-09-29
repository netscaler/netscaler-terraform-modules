resource "azurerm_virtual_network" "terraform-virtual-network" {
  name                = "terraform-virtual-network"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraform-resource-group.name
  address_space       = [var.virtual_network_address_space]
}

resource "azurerm_subnet" "terraform-management-subnet" {
  name                 = "terraform-management-subnet"
  resource_group_name  = azurerm_resource_group.terraform-resource-group.name
  virtual_network_name = azurerm_virtual_network.terraform-virtual-network.name
  address_prefixes     = [var.management_subnet_address_prefix]
}

resource "azurerm_subnet" "terraform-server-subnet" {
  name                 = "terraform-server-subnet"
  resource_group_name  = azurerm_resource_group.terraform-resource-group.name
  virtual_network_name = azurerm_virtual_network.terraform-virtual-network.name
  address_prefixes     = [var.server_subnet_address_prefix]
}

resource "azurerm_subnet" "terraform-client-subnet" {
  name                 = "terraform-client-subnet"
  resource_group_name  = azurerm_resource_group.terraform-resource-group.name
  virtual_network_name = azurerm_virtual_network.terraform-virtual-network.name
  address_prefixes     = [var.client_subnet_address_prefix]
}

resource "azurerm_subnet_network_security_group_association" "management-subnet-association" {
  subnet_id                 = azurerm_subnet.terraform-management-subnet.id
  network_security_group_id = azurerm_network_security_group.terraform-management-subnet-security-group.id
}


resource "azurerm_network_security_group" "terraform-management-subnet-security-group" {
  name                = "terraform-management-subnet-security-group"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraform-resource-group.name
}

// Allow ssh, http and https from controlling subnet
resource "azurerm_network_security_rule" "terraform-allow-all-from-controlling-subnet" {
  name                        = "terraform-allow-all-from-controlling-subnet"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["22", "80", "443"]
  source_address_prefix       = var.controlling_subnet
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.terraform-resource-group.name
  network_security_group_name = azurerm_network_security_group.terraform-management-subnet-security-group.name
}

resource "azurerm_subnet_network_security_group_association" "client-subnet-association" {
  subnet_id                 = azurerm_subnet.terraform-client-subnet.id
  network_security_group_id = azurerm_network_security_group.terraform-client-subnet-security-group.id
}

resource "azurerm_network_security_group" "terraform-client-subnet-security-group" {
  name                = "terraform-client-subnet-security-group"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraform-resource-group.name
}

// Allow http and https from everywhere
resource "azurerm_network_security_rule" "terraform-allow-client-http-from-internet" {
  name                        = "terraform-allow-client-http-from-internet"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.terraform-resource-group.name
  network_security_group_name = azurerm_network_security_group.terraform-client-subnet-security-group.name
}

resource "azurerm_subnet_network_security_group_association" "server-subnet-association" {
  subnet_id                 = azurerm_subnet.terraform-server-subnet.id
  network_security_group_id = azurerm_network_security_group.terraform-server-subnet-security-group.id
}

resource "azurerm_network_security_group" "terraform-server-subnet-security-group" {
  name                = "terraform-server-subnet-security-group"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraform-resource-group.name
}

// Next two rules: Allow server subnet to reply only inside its own subnet
resource "azurerm_network_security_rule" "terraform-server-allow-outbound" {
  name                   = "terraform-server-allow-subnet-outbound"
  priority               = 1000
  direction              = "Outbound"
  access                 = "Allow"
  protocol               = "*"
  source_port_range      = "*"
  destination_port_range = "*"
  source_address_prefix  = "*"
  destination_address_prefixes = [
    azurerm_subnet.terraform-server-subnet.address_prefixes[0],
  ]
  resource_group_name         = azurerm_resource_group.terraform-resource-group.name
  network_security_group_name = azurerm_network_security_group.terraform-server-subnet-security-group.name
}

resource "azurerm_network_security_rule" "terraform-server-deny-all-outbound" {
  name                        = "terraform-server-deny-all-outbound"
  priority                    = 1010
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.terraform-resource-group.name
  network_security_group_name = azurerm_network_security_group.terraform-server-subnet-security-group.name
}
