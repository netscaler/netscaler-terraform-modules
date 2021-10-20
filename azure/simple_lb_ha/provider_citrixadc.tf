terraform {
  required_providers {
    citrixadc = {
      source = "citrix/citrixadc"
    }
  }
}

provider "citrixadc" {
  endpoint             = format("https://%s", element(var.nsips, 0))
  username             = var.adc_admin_username
  password             = var.adc_admin_password
  insecure_skip_verify = true
  alias                = "node0"
}

provider "citrixadc" {
  endpoint             = format("https://%s", element(var.nsips, 1))
  username             = var.adc_admin_username
  password             = var.adc_admin_password
  insecure_skip_verify = true
  alias                = "node1"
}
