terraform {
  required_providers {
    citrixadc = {
      source = "citrix/citrixadc"
    }
  }
}

provider "citrixadc" {
  endpoint             = format("https://%s", var.nsip)
  username             = var.adc_admin_username
  password             = var.adc_admin_password
  insecure_skip_verify = true
}
