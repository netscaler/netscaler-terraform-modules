variable "resource_group_name" {
  description = "Name for the resource group that will contain all created resources"
  default     = "terraform-resource-group"
}

variable "name" {
  description = "Name for the network security rule"
}

variable "priority" {
  description = "Priorty of network security rule"
  default = 100
}

variable "direction" {
  description = "Direction of network security rule"
  default = "Inbound"
}

variable "access" {
  description = "Access of network security rule"
  default = "Allow"
}

variable "protocol" {
  description = "Protocol for network security rule"
  default = "*"
}

variable "source_port_range" {
  description = "source port range for network security rule"
  default = "*"
}

variable "destination_port_range" {
  description = "destination port range for network security rule"
  default = "*"
}

variable "source_address_prefixes" {
  description = "source address prefixes for network security rule"
  default = "*"
}

variable "destination_address_prefixes" {
  description = "destination address prefixes for network security rule"
  default = "*"
}

variable "network_security_group_name" {
  description = "Name for the network security group"
}

