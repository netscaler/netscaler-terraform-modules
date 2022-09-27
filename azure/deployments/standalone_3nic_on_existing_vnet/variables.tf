variable "resource_group_name" {
  type        = string
  description = "Resource_group_name"
}
variable "virtual_network_name" {
  type        = string
  description = "virtual_network_name"
}
variable "management_subnet_name" {
  type        = string
  description = "management_subnet_name"
}
variable "client_subnet_name" {
  type        = string
  description = "client_subnet_name"
}
variable "server_subnet_name" {
  type        = string
  description = "server_subnet_name"
}
variable "location" {
  type = string
}
variable "controlling_subnet" {
  description = "The CIDR block of the machines that will be allowed access to the management subnet."
}
variable "ubuntu_vm_size" {
  description = "Size for the ubuntu machine."
  default     = "Standard_A1_v2"
}
variable "ssh_public_key_file" {
  description = "Public key file for accessing the ubuntu bastion machine."
  default     = "~/.ssh/id_rsa.pub"
}
variable "adc_vm_size" {
  description = "Size for the ADC machine. Must allow for 3 NICs."
  default     = "Standard_F8s_v2"
}
variable "adc_admin_username" {
  description = "User name for the Citrix ADC admin user."
  default     = "nsroot"
}
variable "adc_admin_password" {
  description = "Password for the Citrix ADC admin user. Must be sufficiently complex to pass azurerm provider checks."
}