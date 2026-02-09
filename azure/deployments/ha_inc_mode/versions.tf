terraform {
  required_providers {
    citrixadc = {
      source  = "citrix/citrixadc"
      version = "2.1.0" # tested for 1.29.0 version. Should work for later versions as well.
    }
  }
}

data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../provision_two_vpx/terraform.tfstate"
  }
}

provider "citrixadc" {
  endpoint = format("http://%s", data.terraform_remote_state.infra.outputs.public_nsips[0])
  username = var.adc_admin_username
  password = var.adc_admin_password
}

provider "citrixadc" {
  alias    = "netscaler2"
  endpoint = format("http://%s", data.terraform_remote_state.infra.outputs.public_nsips[1])
  username = var.adc_admin_username
  password = var.adc_admin_password
}
