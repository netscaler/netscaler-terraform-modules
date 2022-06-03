variable "aws_region" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}

locals {
  region               = var.aws_region
  resource_name_prefix = "tf-test-ha-across-az"

  vpc_cidr = "10.0.0.0/16"

  primary_management_subnet_cidr = "10.0.1.0/24"
  primary_client_subnet_cidr     = "10.0.2.0/24"
  primary_server_subnet_cidr     = "10.0.3.0/24"

  restricted_citrixadc_admin_access_cidr = "106.51.0.0/16"
  citrixadc_admin_password               = "verysecretpassword"
}

module "vpc_infra" {
  source = "../../modules/aws_vpc_infra"

  deploy_prefix = local.resource_name_prefix

  vpc_cidr = local.vpc_cidr

  public_subnets = [
    {
      cidr = local.primary_management_subnet_cidr,
      az   = "${local.region}a"
    },
    {
      cidr = local.primary_client_subnet_cidr,
      az   = "${local.region}a"
    },
  ]
  private_subnets = [
    {
      cidr = local.primary_server_subnet_cidr,
      az   = "${local.region}a"
    },
  ]

  create_nat_gateways = false
}

# TODO: add output block