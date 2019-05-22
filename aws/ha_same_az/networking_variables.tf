variable "vpc_cidr_block" {
  description = "The CIDR block that will be used for all needed subnets"
}

variable "management_subnet_cidr_block" {
  description = "The CIDR block that will be used for the management subnet. Must be contained inside the VPC cidr block."
}

variable "client_subnet_cidr_block" {
  description = "The CIDR block that will be used for the client subnet. Must be contained inside the VPC cidr block."
}

variable "server_subnet_cidr_block" {
  description = "The CIDR block that will be used for the server subnet. Must be contained inside the VPC cidr block."
}

variable "controlling_subnet" {
  description = "The CIDR block of the machines that will SSH into the NSIPs of the VPX HA pair."
}
