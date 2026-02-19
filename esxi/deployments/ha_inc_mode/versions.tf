terraform {
  required_providers {
    citrixadc = {
      source = "citrix/citrixadc"
    }
  }
}

# Read outputs from provision_two_vpx deployment
data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../provision_two_vpx/terraform.tfstate"
  }
}

# Provider for NetScaler Node 1
provider "citrixadc" {
  endpoint = format("http://%s", data.terraform_remote_state.infra.outputs.nsip[0])
  username = var.adc_admin_username
  password = var.adc_admin_password
}

# Provider for NetScaler Node 2
provider "citrixadc" {
  alias    = "netscaler2"
  endpoint = format("http://%s", data.terraform_remote_state.infra.outputs.nsip[1])
  username = var.adc_admin_username
  password = var.adc_admin_password
}
