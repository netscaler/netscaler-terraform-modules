provider "vsphere" {
  user           = "root"
  password       = "Freebsd123$%^"
  vsphere_server = "10.106.195.4"

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
