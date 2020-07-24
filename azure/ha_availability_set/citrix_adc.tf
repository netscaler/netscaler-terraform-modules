resource "azurerm_public_ip" "terraform-adc-management-public-ip" {
  name                = format("terraform-adc-management-public-ip-node-%v", count.index)
  resource_group_name = azurerm_resource_group.terraform-resource-group.name
  location            = var.location
  allocation_method   = "Static"

  count = 2
}

resource "azurerm_network_interface" "terraform-adc-management-interface" {
  name                = format("terraform-adc-management-interface-node-%v", count.index)
  location            = var.location
  resource_group_name = azurerm_resource_group.terraform-resource-group.name

  ip_configuration {
    name                          = "management"
    subnet_id                     = azurerm_subnet.terraform-management-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.terraform-adc-management-public-ip.*.id, count.index)
  }
  count = 2
}

resource "azurerm_network_interface" "terraform-adc-client-interface" {
  name                = format("terraform-adc-client-interface-node-%v", count.index)
  location            = var.location
  resource_group_name = azurerm_resource_group.terraform-resource-group.name

  ip_configuration {
    name                          = "client"
    subnet_id                     = azurerm_subnet.terraform-client-subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  count = 2
}

resource "azurerm_network_interface" "terraform-adc-server-interface" {
  name                = format("terraform-adc-server-interface-node-%v", count.index)
  location            = var.location
  resource_group_name = azurerm_resource_group.terraform-resource-group.name

  ip_configuration {
    name                          = "server"
    subnet_id                     = azurerm_subnet.terraform-server-subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  count = 2
}


resource "azurerm_virtual_machine" "terraform-adc-machine" {
  name                = format("terraform-adc-machine-node-%v", count.index)
  resource_group_name = azurerm_resource_group.terraform-resource-group.name
  location            = var.location
  vm_size             = var.adc_vm_size

  network_interface_ids = [
    element(azurerm_network_interface.terraform-adc-management-interface.*.id, count.index),
    element(azurerm_network_interface.terraform-adc-client-interface.*.id, count.index),
    element(azurerm_network_interface.terraform-adc-server-interface.*.id, count.index),
  ]

  primary_network_interface_id = element(azurerm_network_interface.terraform-adc-management-interface.*.id, count.index)

  os_profile {
    computer_name  = format("Citrix-ADC-VPX-node-%v", count.index)
    admin_username = var.adc_admin_username
    admin_password = var.adc_admin_password
    custom_data = jsonencode({
      "vpx_config" = {
        subnet_11 = var.server_subnet_address_prefix,
        snip_11   = element(azurerm_network_interface.terraform-adc-client-interface.*.private_ip_address, count.index),
        subnet_12 = var.client_subnet_address_prefix,
        pvt_ip_12 = element(azurerm_network_interface.terraform-adc-server-interface.*.private_ip_address, count.index),
      }
      "ha_config" = { peer_node = count.index == 0 ? element(azurerm_network_interface.terraform-adc-management-interface.*.private_ip_address, 1) : element(azurerm_network_interface.terraform-adc-management-interface.*.private_ip_address, 0) }
    })
  }

  availability_set_id = azurerm_availability_set.terraform-availability-set.id

  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
      key_data = file(var.ssh_public_key_file)
      path     = format("/home/%v/.ssh/authorized_keys", var.adc_admin_username)
    }
  }

  delete_os_disk_on_termination = true

  storage_os_disk {
    name              = format("terraform-citrixadc-os-disk-node-%v", count.index)
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

  count = 2
}
