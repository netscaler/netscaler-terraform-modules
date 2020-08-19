resource "azurerm_resource_group" "terraform-resource-group" {
  name     = var.resource_group_name
  location = var.location
}

