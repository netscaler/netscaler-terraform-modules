resource "azurerm_resource_group" "terraform-resource-group" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_availability_set" "terraform-availability-set" {
  name                = "terraform-availability-set"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraform-resource-group.name

  platform_update_domain_count = 2
  platform_fault_domain_count  = 2

}
