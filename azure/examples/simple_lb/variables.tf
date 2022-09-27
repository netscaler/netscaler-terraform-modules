variable "resource_group_name" {
  description = "Name for the existing resource group ADC is deployed in."
}

variable "location" {
  description = "Azure location where all resources will be created."
}

variable "server_subnet_id" {
  description = "Server subent id. This where the web server interface will be created."
}

variable "management_subnet_id" {
  description = "Management subnet id."
}

variable "ssh_public_key_file" {
  description = "Public key file for accessing the ubuntu machine."
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_file" {
  description = "Private key file for accessing the ubuntu machine."
  default     = "~/.ssh/id_rsa"
}

variable "admin_user" {
  description = "Admin user name for ubuntu machine."
  default     = "adminuser"
}

variable "vm_size" {
  description = "Size for the ubuntu machine. Must allow for 2 NICs"
  default     = "Standard_A1_v2"
}

variable "num_services" {
  description = "Number of backend services to instantiate"
  default     = 2
}

variable "private_vip" {
  description = "Private ip address of the Citrix ADC client interface"
}

variable "nsip" {
  description = "NSIP to be used with the citrixadc provider."
}

variable "ubuntu_setup_wait_sec" {
  description = "Wait period before starting to setup backend ubuntu node"
  default     = 120
}

variable "adc_admin_username" {
  description = "User name for the Citrix ADC admin user."
  default     = "nsroot"
}

variable "adc_admin_password" {
  description = "Password for the Citrix ADC admin user. Must be sufficiently complex to pass azurerm provider checks."
}
