resource "azurerm_public_ip" "terraform-ubuntu-public-ip" {
  name                = "terraform-ubuntu-public-ip"
  resource_group_name = azurerm_resource_group.terraform-resource-group.name
  location            = var.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "terraform-ubuntu-management-interface" {
  name                = "terraform-ubuntu-management-interface"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraform-resource-group.name

  ip_configuration {
    name                          = "management"
    subnet_id                     = azurerm_subnet.terraform-management-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terraform-ubuntu-public-ip.id
  }

  depends_on = [azurerm_subnet_network_security_group_association.management-subnet-association]
}

resource "azurerm_linux_virtual_machine" "terraform-ubuntu-machine" {
  name                = "terraform-ubuntu-bastion-machine"
  resource_group_name = azurerm_resource_group.terraform-resource-group.name
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
