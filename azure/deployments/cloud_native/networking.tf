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

# VNET Peering from HA to Openshift VNET.
# This will be created only when "create_ha_for_openshift" is set to "true".
resource "azurerm_virtual_network_peering" "ha-to-openshift-vnet-peering" {
  name                      = "peer1to2"
  resource_group_name       = azurerm_resource_group.terraform-resource-group.name
  virtual_network_name      = azurerm_virtual_network.terraform-virtual-network.name
  remote_virtual_network_id = data.azurerm_virtual_network.openshift-vnet[0].id

  count = var.create_ha_for_openshift ? 1 : 0
}

# VNET Peering from Openshift to HA VNET.
# This will be created only when "create_ha_for_openshift" is set to "true".
resource "azurerm_virtual_network_peering" "openshift-to-ha-vnet-peering" {
  name                      = "peer2to1"
  resource_group_name       = data.azurerm_virtual_network.openshift-vnet[0].resource_group_name
  virtual_network_name      = data.azurerm_virtual_network.openshift-vnet[0].name
  remote_virtual_network_id = azurerm_virtual_network.terraform-virtual-network.id

  count = var.create_ha_for_openshift ? 1 : 0
}

# Route table for HA node to reach OpenShift POD network.
# It also creates routes in Citrix ADC VPXs to reach OpenShift Node and Pod Network via HA server subnet.
# This will be created only when "create_ha_for_openshift" is set to "true".
module "ha_openshift_route_table" {
  source = "./azure_route_table"

  location            = var.location
  resource_group_name = var.resource_group_name

  citrixadc_nsips = azurerm_network_interface.terraform-adc-management-interface.*.private_ip_address
  #  ha_server_subnet_prefix = var.server_subnet_address_prefix
  ha_server_subnet     = azurerm_subnet.terraform-server-subnet
  adc_admin_username   = var.adc_admin_username
  adc_admin_password   = var.adc_admin_password
  bastion_public_ip    = azurerm_public_ip.terraform-ubuntu-public-ip.ip_address
  ubuntu_admin_user    = var.ubuntu_admin_user
  ssh_private_key_file = var.ssh_private_key_file

  openshift_worker_subnet_prefix    = data.azurerm_subnet.openshift-worker-subnet[0].address_prefixes[0]
  openshift_master_subnet_prefix    = data.azurerm_subnet.openshift-master-subnet[0].address_prefixes[0]
  openshift_route_address_prefixes  = local.openshift_cluster_host_network_list
  openshift_route_addresses_details = var.openshift_cluster_host_network_details

  count = var.create_ha_for_openshift ? 1 : 0

  depends_on = [
    azurerm_virtual_machine.terraform-adc-machine
  ]
}

# Network security rule in Openshift Network Security Group for allowing traffic from HA SNIPs.
# This will be created only when "create_ha_for_openshift" is set to "true".
module "openshift_network_security_rule" {
  source = "./azure_network_security_rule"

  resource_group_name = data.azurerm_network_security_group.openshift-nsg[0].resource_group_name
  name                = "Allow_traffic_from_VPX_HA_SNIPs"
  #  source_address_prefixes = [element(azurerm_network_interface.terraform-adc-server-interface.*.private_ip_address, 1),element(azurerm_network_interface.terraform-adc-server-interface.*.private_ip_address,2)]
  source_address_prefixes     = local.snip_addresses
  network_security_group_name = data.azurerm_network_security_group.openshift-nsg[0].name

  count = var.create_ha_for_openshift ? 1 : 0

  depends_on = [
    azurerm_network_interface.terraform-adc-server-interface
  ]
}
