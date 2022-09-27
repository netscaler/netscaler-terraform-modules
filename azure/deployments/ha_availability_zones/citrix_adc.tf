resource "azurerm_public_ip" "terraform-adc-management-public-ip" {
  name                = format("terraform-adc-management-public-ip-node-%v", count.index)
  resource_group_name = azurerm_resource_group.terraform-resource-group.name
  location            = var.location
  allocation_method   = "Static"

  sku = "Standard"

  availability_zone = format("%v", count.index + 1)

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

  depends_on = [azurerm_subnet_network_security_group_association.management-subnet-association]

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

  depends_on = [azurerm_subnet_network_security_group_association.client-subnet-association]

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

  depends_on = [azurerm_subnet_network_security_group_association.server-subnet-association]

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

  zones = formatlist("%v", [count.index + 1])

  os_profile {
    computer_name  = format("Citrix-ADC-VPX-node-%v", count.index)
    admin_username = var.adc_admin_username
    admin_password = var.adc_admin_password
    custom_data = base64encode(<<-EOT
      <NS-PRE-BOOT-CONFIG>
        <NS-CONFIG>
          %{if var.ha_for_internal_lb}
            add ip ${azurerm_lb.tf_lb.frontend_ip_configuration.0.private_ip_address} ${cidrnetmask(azurerm_subnet.terraform-client-subnet.address_prefixes.0)} -type VIP
          %{else}
            add ip ${azurerm_public_ip.terraform-load-balancer-public-ip.0.ip_address} ${cidrnetmask(azurerm_subnet.terraform-client-subnet.address_prefixes.0)} -type VIP
          %{endif}
          add ip ${element(azurerm_network_interface.terraform-adc-client-interface.*.private_ip_address, count.index)} ${cidrnetmask(azurerm_subnet.terraform-client-subnet.address_prefixes.0)} -type SNIP
          add ip ${element(azurerm_network_interface.terraform-adc-server-interface.*.private_ip_address, count.index)} ${cidrnetmask(azurerm_subnet.terraform-server-subnet.address_prefixes.0)} -type SNIP
          set systemparameter -promptString "%u@%s"
          add ha node 1 ${count.index == 0 ? element(azurerm_network_interface.terraform-adc-management-interface.*.private_ip_address, 1) : element(azurerm_network_interface.terraform-adc-management-interface.*.private_ip_address, 0)} -inc ENABLED
        </NS-CONFIG>
      </NS-PRE-BOOT-CONFIG>
    EOT
    )
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

  depends_on = [
    azurerm_subnet_network_security_group_association.server-subnet-association,
    azurerm_subnet_network_security_group_association.client-subnet-association,
    azurerm_subnet_network_security_group_association.management-subnet-association,
    azurerm_network_interface_backend_address_pool_association.tf_assoc,
  ]

  count = 2
}
