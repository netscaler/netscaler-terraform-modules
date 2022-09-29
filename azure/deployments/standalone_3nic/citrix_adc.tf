resource "azurerm_public_ip" "terraform-adc-management-public-ip" {
  name                = "terraform-adc-management-public-ip"
  resource_group_name = azurerm_resource_group.terraform-resource-group.name
  location            = var.location
  allocation_method   = "Static"

}

resource "azurerm_network_interface" "terraform-adc-management-interface" {
  name                = "terraform-adc-management-interface"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraform-resource-group.name

  ip_configuration {
    name                          = "management"
    subnet_id                     = azurerm_subnet.terraform-management-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terraform-adc-management-public-ip.id
  }

  depends_on = [azurerm_subnet_network_security_group_association.management-subnet-association]
}

resource "azurerm_public_ip" "terraform-adc-client-public-ip" {
  name                = "terraform-adc-client-public-ip"
  resource_group_name = azurerm_resource_group.terraform-resource-group.name
  location            = var.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "terraform-adc-client-interface" {
  name                = "terraform-adc-client-interface"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraform-resource-group.name

  ip_configuration {
    name                          = "client"
    subnet_id                     = azurerm_subnet.terraform-client-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terraform-adc-client-public-ip.id
  }

  depends_on = [azurerm_subnet_network_security_group_association.client-subnet-association]
}

resource "azurerm_network_interface" "terraform-adc-server-interface" {
  name                = "terraform-adc-server-interface"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraform-resource-group.name

  ip_configuration {
    name                          = "client"
    subnet_id                     = azurerm_subnet.terraform-server-subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [azurerm_subnet_network_security_group_association.server-subnet-association]
}


resource "azurerm_virtual_machine" "terraform-adc-machine" {
  name                = "terraform-adc-machine"
  resource_group_name = azurerm_resource_group.terraform-resource-group.name
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
      "subnet_11" = var.server_subnet_address_prefix,
      "pvt_ip_11" = azurerm_network_interface.terraform-adc-client-interface.private_ip_address,
      "subnet_12" = var.client_subnet_address_prefix,
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
