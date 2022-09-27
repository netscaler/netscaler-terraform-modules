variable "reset_password" {
  description = "Set this to true for first time password reset operation."
  type        = bool
}

variable "new_password" {
  description = "The new ADC password that will replace the default one. Applicable only when reset_password variable is set to `true`"
}

variable "reset_delay_sec" {
  description = "Time period to wait to start password reset operation after ADC creation. Should be enough for bootstrap scripts to have finished execution. Applicable only when reset_password variable is set to `true`"
  default     = 120
}
