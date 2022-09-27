locals {
  pod_network_nsip_association = flatten([
    for prefix in var.openshift_route_address_prefixes : [
      for ip in var.citrixadc_nsips : {
        nsip   = ip
        subnet_prefix = prefix
      }
    ]
  ])
  worker_subnet_nsip_association = flatten([
    for ip in var.citrixadc_nsips : {
      nsip = ip
      subnet_prefix = var.openshift_worker_subnet_prefix
    }
  ])
  master_subnet_nsip_association = flatten([
    for ip in var.citrixadc_nsips : {
      nsip = ip
      subnet_prefix = var.openshift_master_subnet_prefix
    }
  ])
  subnet_nsip_association = concat(local.pod_network_nsip_association,local.worker_subnet_nsip_association,local.master_subnet_nsip_association)
}

variable "resource_group_name" {
  description = "Name for the resource group that will contain all created resources"
  default     = "terraform-resource-group"
}

variable "location" {
  description = "Azure location where all resources will be created"
}

variable "openshift_route_address_prefixes" {
  description = "List of prefixes for which routes needs to be created"
  type = list(string)
}

variable "openshift_route_addresses_details" {
  description = "List of routes details. Key are route prefix and value is route gateway"
  type = map(string)
}

variable "citrixadc_nsips" {
  description = "Management IPs of Citrix ADC"
}

variable "ha_server_subnet" {
  description = "Gateway of Citrix ADC Server Subnet"
}

variable "openshift_worker_subnet_prefix" {
  description = "OpenShift worker subnet prefix"
}

variable "openshift_master_subnet_prefix" {
  description = "OpenShift master subnet prefix"
}

variable "adc_admin_username" {
  description = "User name for the Citrix ADC admin user."
  default     = "nsroot"
}

variable "adc_admin_password" {
  description = "Password for the Citrix ADC admin user. Must be sufficiently complex to pass azurerm provider checks."
}

variable "bastion_public_ip" {
  description = "Public IP of the created Bastion Server"

}

variable "ubuntu_admin_user" {
  description = "The Admin Username of the created Bastion Server"
}

variable "ssh_private_key_file" {
  description = "Private key file for accessing the ubuntu bastion machine."
  default     = "~/.ssh/id_rsa"
}
