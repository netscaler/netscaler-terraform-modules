variable "region" {
  description = "Region to deploy resources to"
}

variable "zone" {
  description = "Zone to deploy resources to"
}

variable "project" {
  description = "Project to deploy resources"
}

variable "public_ssh_key_file" {
  description = "Location of the public part of the SSH key with which to access the management interface"
}
variable "citrixadc_rpc_node_password" {
  description = "The new ADC RPC node password that will replace the default one on both ADC instances. [Learn More about RPCNode](https://docs.citrix.com/en-us/citrix-adc/current-release/getting-started-with-citrix-adc/change-rpc-node-password.html)"
}