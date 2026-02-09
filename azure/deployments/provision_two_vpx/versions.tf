terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.27.0"
    }
  
    citrixadc = {
      source  = "citrix/citrixadc"
      version = "2.1.0" # tested for 1.29.0 version. Should work for later versions as well.
    }
  }
}
provider "azurerm" {
  features {}
}

# provider "citrixadc" {
#   endpoint = format("http://%s", azurerm_public_ip.terraform-adc-management-public-ip[0].ip_address)
#   username = var.adc_admin_username
#   password = var.adc_admin_password
# }

# provider "citrixadc" {
#   alias    = "netscaler2"
#   endpoint = format("http://%s", azurerm_public_ip.terraform-adc-management-public-ip[1].ip_address)
#   username = var.adc_admin_username
#   password = var.adc_admin_password
# }
