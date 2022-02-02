##############
#    ALB     #
##############

resource "azurerm_public_ip" "terraform-load-balancer-public-ip" {
  count               = var.ha_for_internal_lb ? 0 : 1
  name                = "tf_lb_pubip"
  resource_group_name = azurerm_resource_group.terraform-resource-group.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

}

resource "azurerm_network_interface_backend_address_pool_association" "tf_assoc" {
  network_interface_id    = element(azurerm_network_interface.terraform-adc-client-interface.*.id, count.index)
  ip_configuration_name   = "client"
  backend_address_pool_id = azurerm_lb_backend_address_pool.tf_backend_pool.id

  count = 2
}

resource "azurerm_lb_rule" "allow_http" {
  resource_group_name            = azurerm_resource_group.terraform-resource-group.name
  loadbalancer_id                = azurerm_lb.tf_lb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = var.ha_for_internal_lb ? "PrivateIPAddress" : "PublicIPAddress"
  enable_floating_ip             = true
  idle_timeout_in_minutes        = 4
  load_distribution              = "Default"
  probe_id                       = azurerm_lb_probe.tf_probe.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.tf_backend_pool.id
}

resource "azurerm_lb_backend_address_pool" "tf_backend_pool" {
  loadbalancer_id = azurerm_lb.tf_lb.id
  name            = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "tf_probe" {
  resource_group_name = azurerm_resource_group.terraform-resource-group.name
  loadbalancer_id     = azurerm_lb.tf_lb.id
  name                = "http-probe"
  port                = 9000
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb" "tf_lb" {
  name                = "tf_lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraform-resource-group.name
  sku                 = "Standard"


  frontend_ip_configuration {
    name                 = var.ha_for_internal_lb ? "PrivateIPAddress" : "PublicIPAddress"
    public_ip_address_id = var.ha_for_internal_lb ? null : azurerm_public_ip.terraform-load-balancer-public-ip.0.id
    subnet_id            = var.ha_for_internal_lb ? azurerm_subnet.terraform-client-subnet.id : null
  }
}
