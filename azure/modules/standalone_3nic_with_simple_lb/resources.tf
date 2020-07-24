module "standalone_3nic" {
  source = "../../standalone_3nic"

  location = var.location

  virtual_network_address_space    = var.virtual_network_address_space
  management_subnet_address_prefix = var.management_subnet_address_prefix
  client_subnet_address_prefix     = var.client_subnet_address_prefix
  server_subnet_address_prefix     = var.server_subnet_address_prefix

  adc_admin_password = var.adc_admin_password

  controlling_subnet = var.controlling_subnet
}

module "simple_lb" {
  source = "../../simple_lb"

  resource_group_name = var.resource_group_name

  location = var.location

  management_subnet_id = module.standalone_3nic.management_subnet_id
  server_subnet_id     = module.standalone_3nic.server_subnet_id

  private_vip = module.standalone_3nic.private_vip
  nsip        = module.standalone_3nic.public_nsip

  adc_admin_password = var.adc_admin_password
}
