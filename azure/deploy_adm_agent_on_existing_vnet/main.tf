# data sources for existing resource_group, virtual_network and subnet
data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "virtual_network" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

data "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  virtual_network_name = data.azurerm_virtual_network.virtual_network.name
  resource_group_name  = data.azurerm_resource_group.resource_group.name
}

resource "azurerm_network_interface_security_group_association" "interface_securitygroup_association" {
  network_interface_id      = azurerm_network_interface.terraform_agent_interface.id
  network_security_group_id = azurerm_network_security_group.terraform_security_group.id
}

resource "azurerm_network_security_group" "terraform_security_group" {
  name                = "terraform_security_group"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

#ssh command
resource "azurerm_network_security_rule" "terraform-ssh" {
  name                        = "terraform-ssh"
  priority                    = 900
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.admin_ip_address
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.terraform_security_group.name
}

resource "azurerm_public_ip" "terraform-agent-public-ip" {
  name                = "terraform-agent-public-ip"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
}

resource "azurerm_network_interface" "terraform_agent_interface" {
  name                = "terraform_agent_interface"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "management"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terraform-agent-public-ip.id
  }
}

resource "azurerm_virtual_machine" "terraform-adm-agent" {
  name                = var.adm_agent_name
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = var.location
  vm_size             = var.adc_vm_size

  network_interface_ids = [
    azurerm_network_interface.terraform_agent_interface.id,
  ]

  primary_network_interface_id = azurerm_network_interface.terraform_agent_interface.id

  os_profile {
    computer_name  = "Citrix-ADM-Agent"
    admin_username = var.adm_agent_admin_username
    admin_password = var.adm_agent_admin_password
    custom_data    = "registeragent -serviceurl ${var.serviceurl} -activationcode ${var.activationcode}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }

  delete_os_disk_on_termination = true

  storage_os_disk {
    name              = "terraform-adm-agent-os-disk"
    caching           = "ReadWrite"
    managed_disk_type = var.managed_disk_type
    create_option     = "FromImage"
  }

  storage_image_reference {
    publisher = "citrix"
    offer     = var.adm_agent_version_offer
    sku       = "netscaler-ma-service-agent"
    version   = "latest"
  }

  plan {
    name      = "netscaler-ma-service-agent"
    publisher = "citrix"
    product   = var.adm_agent_version_offer
  }

  depends_on = [
    azurerm_network_interface_security_group_association.interface_securitygroup_association,
  ]

}
