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
variable "management_subnet_cidr_block" {
  description = "The CIDR block that will be used for the management subnet."
}

variable "client_subnet_cidr_block" {
  description = "The CIDR block that will be used for the client subnet."
}

variable "server_subnet_cidr_block" {
  description = "The CIDR block that will be used for the server subnet."
}

variable "controlling_subnet" {
  description = "The CIDR block of the machines that will SSH to the NSIP"
}

variable "management_subnet_name" {
  description = "Name for the management subnet"
  default = "management-subnet"
}

variable "client_subnet_name" {
  description = "Name for the client subnet"
  default = "client-subnet"
}

variable "server_subnet_name" {
  description = "Name for the server subnet"
  default = "server-subnet"
}

variable "machine_type" {
  description = "Instance type. Must allow for 3 NICs"
}

variable "image" {
  description = "Image to use for boot disk. Must be an ADC image."
}

variable "vip_alias_range" {
  description = "VIP alias range. Typically a /32 range."
}

variable "zones" {
  description = "List of two zones to deploy primary and secondary instance of HA pair."
}

variable "citrixadc_rpc_node_password" {
  description = "The new ADC RPC node password that will replace the default one on both ADC instances. [Learn More about RPCNode](https://docs.citrix.com/en-us/citrix-adc/current-release/getting-started-with-citrix-adc/change-rpc-node-password.html)"
  sensitive = true
}