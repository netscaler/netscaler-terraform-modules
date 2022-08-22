# data sources for existing resource_group, vnet and 3-subnets
data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

data "azurerm_subnet" "management_subnet" {
  name                 = var.management_subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.resource_group.name
}

data "azurerm_subnet" "client_subnet" {
  name                 = var.client_subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.resource_group.name
}

data "azurerm_subnet" "server_subnet" {
  name                 = var.server_subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.resource_group.name
}


resource "azurerm_subnet_network_security_group_association" "management-subnet-association" {
  subnet_id                 = data.azurerm_subnet.management_subnet.id
  network_security_group_id = azurerm_network_security_group.terraform-management-subnet-security-group.id
}

resource "azurerm_network_security_group" "terraform-management-subnet-security-group" {
  name                = "terraform-management-subnet-security-group"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
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
  resource_group_name         = data.azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.terraform-management-subnet-security-group.name
}


resource "azurerm_subnet_network_security_group_association" "client-subnet-association" {
  subnet_id                 = data.azurerm_subnet.client_subnet.id
  network_security_group_id = azurerm_network_security_group.terraform-client-subnet-security-group.id
}

resource "azurerm_network_security_group" "terraform-client-subnet-security-group" {
  name                = "terraform-client-subnet-security-group"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
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
  resource_group_name         = data.azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.terraform-client-subnet-security-group.name
}

resource "azurerm_subnet_network_security_group_association" "server-subnet-association" {
  subnet_id                 = data.azurerm_subnet.server_subnet.id
  network_security_group_id = azurerm_network_security_group.terraform-server-subnet-security-group.id
}

resource "azurerm_network_security_group" "terraform-server-subnet-security-group" {
  name                = "terraform-server-subnet-security-group"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
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
    data.azurerm_subnet.server_subnet.address_prefixes[0],
  ]
  resource_group_name         = data.azurerm_resource_group.resource_group.name
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
  resource_group_name         = data.azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.terraform-server-subnet-security-group.name
}

resource "azurerm_public_ip" "terraform-ubuntu-public-ip" {
  name                = "terraform-ubuntu-public-ip"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = var.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "terraform-ubuntu-management-interface" {
  name                = "terraform-ubuntu-management-interface"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "management"
    subnet_id                     = data.azurerm_subnet.management_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terraform-ubuntu-public-ip.id
  }

  depends_on = [azurerm_subnet_network_security_group_association.management-subnet-association]
}

# ubuntu bastion host deployment
resource "azurerm_linux_virtual_machine" "terraform-ubuntu-machine" {
  name                = "terraform-ubuntu-bastion-machine"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = var.location
  size                = var.ubuntu_vm_size
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.terraform-ubuntu-management-interface.id
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file(var.ssh_public_key_file)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}


resource "azurerm_public_ip" "terraform-adc-management-public-ip" {
  name                = "terraform-adc-management-public-ip"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = var.location
  allocation_method   = "Static"

}

resource "azurerm_network_interface" "terraform-adc-management-interface" {
  name                = "terraform-adc-management-interface"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "management"
    subnet_id                     = data.azurerm_subnet.management_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terraform-adc-management-public-ip.id
  }

  depends_on = [azurerm_subnet_network_security_group_association.management-subnet-association]
}

resource "azurerm_public_ip" "terraform-adc-client-public-ip" {
  name                = "terraform-adc-client-public-ip"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = var.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "terraform-adc-client-interface" {
  name                = "terraform-adc-client-interface"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "client"
    subnet_id                     = data.azurerm_subnet.client_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terraform-adc-client-public-ip.id
  }

  depends_on = [azurerm_subnet_network_security_group_association.client-subnet-association]
}

resource "azurerm_network_interface" "terraform-adc-server-interface" {
  name                = "terraform-adc-server-interface"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "client"
    subnet_id                     = data.azurerm_subnet.server_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [azurerm_subnet_network_security_group_association.server-subnet-association]
}

# The Citrix ADC instance is deployed as a single instance with 3 separate NICs each in a separate subnet.
resource "azurerm_virtual_machine" "terraform-adc-machine" {
  name                = "terraform-adc-machine"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = var.location
  vm_size             = var.adc_vm_size

  network_interface_ids = [
    azurerm_network_interface.terraform-adc-management-interface.id,
    azurerm_network_interface.terraform-adc-client-interface.id,
    azurerm_network_interface.terraform-adc-server-interface.id,
  ]

  primary_network_interface_id = azurerm_network_interface.terraform-adc-management-interface.id

  os_profile {
    computer_name  = "Citrix-ADC-VPX"
    admin_username = var.adc_admin_username
    admin_password = var.adc_admin_password
    custom_data = jsonencode({
      "subnet_11" = data.azurerm_subnet.server_subnet.address_prefix,
      "pvt_ip_11" = azurerm_network_interface.terraform-adc-client-interface.private_ip_address,
      "subnet_12" = data.azurerm_subnet.client_subnet.address_prefix,
      "pvt_ip_12" = azurerm_network_interface.terraform-adc-server-interface.private_ip_address,
    })
  }

  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
      key_data = file(var.ssh_public_key_file)
      path     = format("/home/%v/.ssh/authorized_keys", var.adc_admin_username)
    }
  }

  delete_os_disk_on_termination = true

  storage_os_disk {
    name              = "terraform-citrixadc-os-disk"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }

  storage_image_reference {
    publisher = "citrix"
    offer     = "netscalervpx-130"
    sku       = "netscalervpxexpress"
    version   = "latest"
  }

  plan {
    name      = "netscalervpxexpress"
    publisher = "citrix"
    product   = "netscalervpx-130"
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.server-subnet-association,
    azurerm_subnet_network_security_group_association.client-subnet-association,
    azurerm_subnet_network_security_group_association.management-subnet-association,
  ]
}