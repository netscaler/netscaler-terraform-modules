###############################
#    Private ALB for NSIP     #
###############################

resource "azurerm_network_interface_backend_address_pool_association" "tf_nsip_assoc" {
  network_interface_id    = element(var.citrixadc_management_nic.*.id, count.index)

  ip_configuration_name   = "management"
  backend_address_pool_id = azurerm_lb_backend_address_pool.tf_internal_backend_pool.id

  count = 2
}

resource "azurerm_lb_rule" "allow_http_nsip" {
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.tf_internal_lb.id
  name                           = "NitroHTTPRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PrivateIPAddress"
  enable_floating_ip             = true
  idle_timeout_in_minutes        = 4
  load_distribution              = "Default"
  probe_id                       = azurerm_lb_probe.tf_internal_probe.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.tf_internal_backend_pool.id

}

resource "azurerm_lb_rule" "allow_https_nsip" {
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.tf_internal_lb.id
  name                           = "NitroHTTPSRule"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "PrivateIPAddress"
  enable_floating_ip             = true
  idle_timeout_in_minutes        = 4
  load_distribution              = "Default"
  probe_id                       = azurerm_lb_probe.tf_internal_probe.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.tf_internal_backend_pool.id
}

resource "azurerm_lb_backend_address_pool" "tf_internal_backend_pool" {

  loadbalancer_id     = azurerm_lb.tf_internal_lb.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "tf_internal_probe" {

  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.tf_internal_lb.id
  name                = "nsip-http-probe"
  port                = 9000
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb" "tf_internal_lb" {

  name                = "tf_internal_lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PrivateIPAddress"
    subnet_id            = var.management_subnet_id
  }
}

resource "null_resource" "cic_nsip_config_citrix_adc" {
  connection {
    host = var.bastion_public_ip
    user = var.ubuntu_admin_user
    # Should be the private key corresponding to the one used for creating the ubuntu node
    private_key = file(var.ssh_private_key_file)
  }

  depends_on = [
    azurerm_lb.tf_internal_lb
  ]

  provisioner "remote-exec" {
    inline = [
      format("curl -s -k -H \"Content-Type: application/json\" -H \"X-NITRO-USER: %v\" -H \"X-NITRO-PASS: %v\" -d %#v https://%v/nitro/v1/config/nsip", var.adc_admin_username, var.adc_admin_password, jsonencode(
        {nsip={
          ipaddress=azurerm_lb.tf_internal_lb.private_ip_address,
          netmask=var.citrixadc_management_netmask,
          type="SNIP",
          mgmtaccess="ENABLED"
        }}
      ), var.citrixadc_nsips[count.index])
    ]
  }

  count = length(var.citrixadc_nsips)
}
