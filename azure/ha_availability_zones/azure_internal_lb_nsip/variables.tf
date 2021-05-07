variable "resource_group_name" {
  description = "Name for the resource group that will contain all created resources"
  default     = "terraform-resource-group"
}

variable "location" {
  description = "Azure location where all resources will be created"
}

variable "management_subnet_id" {
  description = "Azure management Networks ID"
}

variable "citrixadc_management_nic" {
  description = "Management NIC of Citrix ADC"
}

variable "citrixadc_nsips" {
  description = "Management IPs of Citrix ADC"
}

variable "citrixadc_management_netmask" {
  description = "Subnet Mask for Citrix ADC Management Subnet"
}

variable "adc_admin_username" {
  description = "User name for the Citrix ADC admin user."
  default     = "nsroot"
}

variable "adc_admin_password" {
  description = "Password for the Citrix ADC admin user. Must be sufficiently complex to pass azurerm provider checks."
}

variable "bastion_public_ip" {
  description = "Public IP of the created Bastion Server"
  
}

variable "ubuntu_admin_user" {
  description = "The Admin Username of the created Bastion Server"
}

variable "ssh_private_key_file" {
  description = "Private key file for accessing the ubuntu bastion machine."
  default     = "~/.ssh/id_rsa"
}