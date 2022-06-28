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

  secondary_management_subnet_cidr = "10.0.4.0/24"
  secondary_client_subnet_cidr     = "10.0.5.0/24"
  secondary_server_subnet_cidr     = "10.0.6.0/24"

  restricted_citrixadc_admin_access_cidr = "106.51.0.0/16"
  citrixadc_admin_password               = "verysecretpassword"
  existing_keypair_name                  = "demo_keypair"
}

module "vpc_infra" {
  source = "../../modules/aws_vpc_infra"

  deploy_prefix = local.resource_name_prefix

  vpc_cidr = local.vpc_cidr

  public_subnets = [
    { cidr = local.primary_management_subnet_cidr, az = "${local.region}a" },
    { cidr = local.primary_client_subnet_cidr, az = "${local.region}a" },
    { cidr = local.secondary_management_subnet_cidr, az = "${local.region}b" },
    { cidr = local.secondary_client_subnet_cidr, az = "${local.region}b" },
  ]
  private_subnets = [
    { cidr = local.primary_server_subnet_cidr, az = "${local.region}a" },
    { cidr = local.secondary_server_subnet_cidr, az = "${local.region}b" },
  ]

  create_nat_gateways = false
}

locals {
  primary_management_subnet_id   = module.vpc_infra.public_subnets[0].id
  primary_client_subnet_id       = module.vpc_infra.public_subnets[1].id
  primary_server_subnet_id       = module.vpc_infra.private_subnets[0].id
  secondary_management_subnet_id = module.vpc_infra.public_subnets[2].id
  secondary_client_subnet_id     = module.vpc_infra.public_subnets[3].id
  secondary_server_subnet_id     = module.vpc_infra.private_subnets[1].id
}
