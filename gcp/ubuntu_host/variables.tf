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
