resource "azurerm_public_ip" "terraform-ubuntu-public-ip" {
  name                = format("terraform-backend-service-public-ip-node-%v", count.index)
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"

  count = var.num_services
}

resource "azurerm_network_interface" "terraform-ubuntu-management-interface" {
  name                = format("terraform-backend-service-management-interface-node-%v", count.index)
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "management"
    subnet_id                     = var.management_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.terraform-ubuntu-public-ip.*.id, count.index)
  }

  count = var.num_services
}

resource "azurerm_network_interface" "terraform-ubuntu-server-interface" {
  name                = format("terraform-backend-service-server-interface-node-%v", count.index)
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "server"
    subnet_id                     = var.server_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
  count = var.num_services
}

resource "azurerm_linux_virtual_machine" "terraform-ubuntu-machine" {
  name                = format("terraform-backend-service-machine-node-%v", count.index)
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_user
  network_interface_ids = [
    element(azurerm_network_interface.terraform-ubuntu-management-interface.*.id, count.index),
    element(azurerm_network_interface.terraform-ubuntu-server-interface.*.id, count.index),
  ]

  admin_ssh_key {
    username   = var.admin_user
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

  count = var.num_services
}

resource "citrixadc_lbvserver" "terraform_test_lb" {
  name        = "terraform_test_lb"
  ipv46       = var.private_vip
  port        = "80"
  servicetype = "HTTP"
  lbmethod    = "ROUNDROBIN"
}

resource "citrixadc_servicegroup" "ubuntu_servers" {
  servicegroupname = "terraform_test_servicegroup"
  lbvservers       = [citrixadc_lbvserver.terraform_test_lb.name]
  servicetype      = "HTTP"
  clttimeout       = "40"

  servicegroupmembers = formatlist("%v:80:1", azurerm_network_interface.terraform-ubuntu-server-interface.*.private_ip_address)

}

resource "null_resource" "networking_setup" {
  connection {
    host = element(azurerm_public_ip.terraform-ubuntu-public-ip.*.ip_address, count.index)
    user = var.admin_user
    # Should be the private key corresponding to the one used for creating the ubuntu node
    private_key = file(var.ssh_private_key_file)
  }

  depends_on = [
    azurerm_linux_virtual_machine.terraform-ubuntu-machine
  ]
  provisioner "remote-exec" {
    inline = [
      format("sleep %v", var.ubuntu_setup_wait_sec),
      "sudo apt update -y",
      "sudo apt install -y apache2",
      format(
        "sudo bash -c 'echo \"Hello from backend service %v\" > /var/www/html/index.html'",
        count.index + 1,
      ),
    ]
  }

  count = var.num_services
}
