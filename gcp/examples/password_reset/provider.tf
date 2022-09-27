terraform {
  required_providers {
    citrixadc = {
      source = "citrix/citrixadc"
    }
  }
}

provider "citrixadc" {
  endpoint = format("https://%s", var.primary_nsip)
  password = var.new_password
  insecure_skip_verify = true
}
