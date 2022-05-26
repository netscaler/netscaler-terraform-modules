variable "nsip" {
  description = "NSIP address"
  type = string
}

variable "gw_ip" {
  description = "Gateway IP address"
  type = string
}

variable "subnetmask" {
  description = "Subnet Mask"
  type = string
}

variable "vsphere_ip" {
  description = "IP Address of vsphere"
  type = string
}

variable "vsphere_username" {
  description = "User name for vsphere"
  type = string
}

variable "vsphere_password" {
  description = "vSphere password"
  sensitive = true
  type = string
}

variable "datacenter_name" {
  description = "Data Center name"
  type = string
}

variable "datastore_name" {
  description = "Data Store Name"
  type = string
}

variable "resource_pool_name" {
  description = "Resource Pool Name"
  type = string
}

variable "resource_host" {
  description = "ESXi host ip"
  type = string
}

variable "nic_01_network_name" {
  description = "Network name for 1/1 NIC"
  type = string
}

variable "virtual_machine_name" {
  description = "Virtual machine names in list(string)"
  type        = string
}

variable "remote_vpx_ovf_path" {
  description = "OVF path"
  type = string
}

variable "memory" {
  description = "VPX memory in MB"
  type = number
}

variable "num_cpus" {
  description = "VPX cpu count"
  type = number
}

variable "iso_output_dir" {
  description = "Directory which will be used to construct userdata iso file"
  type = string
  default = "iso_preboot_config"
}

variable "iso_destination_folder" {
  description = "Target directory in datastore to upload iso file"
  type = string
}
