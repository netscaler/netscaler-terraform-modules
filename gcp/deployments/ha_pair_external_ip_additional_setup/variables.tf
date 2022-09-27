variable "primary_nsip" {
  description = "Primary NSIP address"
}

variable "primary_vip_address" {
  description = "Private ip address assigned to primary client interface"
}

variable "primary_vip_netmask" {
  description = "Netmask for primary node client interface"
  default = "255.255.255.0"
}

variable "primary_snip_address" {
  description = "Private ip address assigned to primary server interface"
}

variable "primary_snip_netmask" {
  description = "Netmask for primary node server interface"
  default = "255.255.255.0"
}

variable "secondary_nsip" {
  description = "Secondary NSIP address"
}

variable "secondary_vip_address" {
  description = "Private ip address assigned to secondary client interface"
}

variable "secondary_vip_netmask" {
  description = "Netmask for secondary node client interface"
  default = "255.255.255.0"
}

variable "secondary_snip_address" {
  description = "Private ip address assigned to secondary server interface"
}

variable "secondary_snip_netmask" {
  description = "Netmask for secondary node server interface"
  default = "255.255.255.0"
}

variable "password" {
  description = "Password for the HA pair"
}

variable "ipset_name" {
  description = "Name for the ipset"
}

variable "backend_service_address" {
  description = "Ip address of the backend server"
}
