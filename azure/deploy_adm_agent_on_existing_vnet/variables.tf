variable "resource_group_name" {
  type        = string
  description = "Resource_group_name"
}
variable "virtual_network_name" {
  type        = string
  description = "virtual_network_name"
}
variable "subnet_name" {
  type        = string
  description = "subnet_name"
}

variable "location" {
  type = string
}
variable "adm_agent_name" {
  description = "ADM Agent Name"
}
variable "adc_vm_size" {
  description = "Size for the ADC machine. Must allow for 3 NICs."
  default     = "Standard_D8s_v3"
}
variable "managed_disk_type" {
  description = "Size for Manager Disk"
  default     = "StandardSSD_LRS"
}
variable "adm_agent_version_offer" {
  description = "The Version of ADM Agent to provision"
  default     = "netscaler-ma-service-agent"
}
variable "adm_agent_admin_username" {
  description = "User name for the Citrix ADC admin user."
  default     = "agent"
}
variable "adm_agent_admin_password" {
  description = "Password for the Citrix ADC admin user. Must be sufficiently complex to pass azurerm provider checks."
}
variable "admin_ip_address" {
  description = "IP address of the Admin to manage the Citrix ADM Agent"
}
variable "serviceurl" {
  description = "service_url from the ADM to which you want to register"
}
variable "activationcode" {
  description = "activation_code from the ADM to which you want to register"
}