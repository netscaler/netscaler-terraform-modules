terraform {
  required_providers {
    citrixadc = {
      source = "citrix/citrixadc"
    }
  }
}

provider "citrixadc" {
  endpoint = format("https://%s", var.primary_nsip)
  password = var.password
  insecure_skip_verify = true
  alias = "primary"
}

provider "citrixadc" {
  endpoint = format("https://%s", var.secondary_nsip)
  password = var.password
  insecure_skip_verify = true
  alias = "secondary"
}
