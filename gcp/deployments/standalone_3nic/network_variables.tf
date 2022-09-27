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
