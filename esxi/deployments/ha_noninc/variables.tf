variable "adc_admin_username" {
  description = "User name for the Citrix ADC admin user"
  type        = string
  default     = "nsroot"
}

variable "adc_admin_password" {
  description = "New Password for the Citrix ADC admin user "
  type        = string
  sensitive   = true
}

variable "adc_default_password" {
  description = "Password with the adc boots up by default"
  type        = string
  sensitive   = true
}

variable "citrixadc_rpc_node_password" {
  description = "The new ADC RPC node password that will replace the default one on both ADC instances"
  type        = string
  sensitive   = true
}
