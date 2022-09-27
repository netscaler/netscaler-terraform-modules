variable "primary_nsip" {
  description = "Primary NSIP address"
}

variable "secondary_nsip" {
  description = "Secondary NSIP address"
}

variable "alias_vip_address" {
  description = "Alias VIP address"
}

variable "alias_vip_netmask" {
  description = "Alias VIP netmask"
  default = "255.255.255.0"
}

variable "primary_snip_address" {
  description = "Private ip address assigned to primary server interface"
}

variable "primary_snip_netmask" {
  description = "Netmask for primary node server interface"
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

variable "backend_service_address" {
  description = "Ip address of the backend server"
}
