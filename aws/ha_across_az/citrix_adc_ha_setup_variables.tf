variable "ipset_name" {
  description = "Name for the ipset."
  default     = "ipset_tf"
}

variable "lbvserver_name" {
  description = "Name for the lb vserver."
  default     = "vserver1"
}

variable "server_subnet_mask" {
  description = "Subnet mask for the server network."
  default     = "255.255.255.0"
}

variable "initial_wait_sec" {
  description = "Time interval in seconds to wait before starting the execution of the ha setup script. Should be long enough to allow the ADC to be initialized."
  default     = "120"
}
