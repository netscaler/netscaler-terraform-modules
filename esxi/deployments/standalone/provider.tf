provider "vsphere" {
  user           = "administrator@vsphere.local"
  password       = "Meatfreeburger14$"
  vsphere_server = "10.217.100.101"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
      version = "3.1.1"
    }
  }
}
