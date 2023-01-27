variable "machine_type" {
  description = "Instance type. Must allow for 3 NICs"
}

variable "image" {
  description = "Image to use for boot disk. Must be an ADC image."
}

variable "zones" {
  description = "List of two zones to deploy primary and secondary instance of HA pair."
}

variable "citrixadc_rpc_node_password" {
  description = "The new ADC RPC node password that will replace the default one on both ADC instances. [Learn More about RPCNode](https://docs.citrix.com/en-us/citrix-adc/current-release/getting-started-with-citrix-adc/change-rpc-node-password.html)"
}