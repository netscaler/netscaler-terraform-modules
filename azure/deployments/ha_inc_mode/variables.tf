# variable "netscaler1_nsip" {
#   type        = string
#   description = "NetScaler1 IP Address"
# }
# variable "netscaler2_nsip" {
#   type        = string
#   description = "NetScaler2 IP Address"
# }
variable "adc_admin_username" {
  description = "User name for the Citrix ADC admin user."
  default     = "nsroot"
}
variable "adc_admin_password" {
  description = "Password for the Citrix ADC admin user. Must be sufficiently complex to pass azurerm provider checks."
}
variable "management_subnet_address_prefix" {
  description = "The address prefix that will be used for the management subnet. Must be contained inside the VNet address space"
}
variable "citrixadc_rpc_node_password" {
  type        = string
  sensitive   = true
  description = "The new ADC RPC node password that will replace the default one on both ADC instances. [Learn More about RPCNode](https://docs.citrix.com/en-us/citrix-adc/current-release/getting-started-with-citrix-adc/change-rpc-node-password.html)"
}