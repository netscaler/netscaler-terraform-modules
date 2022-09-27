variable "aws_region" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}

locals {
  region               = var.aws_region
  resource_name_prefix = "tf-bastion"

  vpc_cidr = "10.0.0.0/16"

  primary_management_subnet_cidr = "10.0.1.0/24"
  primary_client_subnet_cidr     = "10.0.2.0/24"
  primary_server_subnet_cidr     = "10.0.3.0/24"

  restricted_citrixadc_admin_access_cidr = "106.51.0.0/16"
  existing_keypair_name                  = "demo_keypair"
}

module "vpc_infra" {
  source = "../../modules/aws_vpc_infra"

  deploy_prefix = local.resource_name_prefix

  vpc_cidr = local.vpc_cidr

  public_subnets = [
    { cidr = local.primary_client_subnet_cidr, az = "${local.region}a" },
  ]
  private_subnets = [
    { cidr = local.primary_management_subnet_cidr, az = "${local.region}a" },
    { cidr = local.primary_server_subnet_cidr, az = "${local.region}a" },
  ]

  create_nat_gateways = false
}

locals {
  vpc_id                       = module.vpc_infra.vpc_id
  primary_client_subnet_id     = module.vpc_infra.public_subnets[0].id
  primary_management_subnet_id = module.vpc_infra.private_subnets[0].id
  primary_server_subnet_id     = module.vpc_infra.private_subnets[1].id
}

module "bastion_host" {
  source = "../../modules/aws_bastion"

  deploy_prefix               = local.resource_name_prefix
  vpc_cidr                    = local.vpc_cidr
  vpc_id                      = local.vpc_id
  restricted_mgmt_access_cidr = local.restricted_citrixadc_admin_access_cidr
  subnet_id                   = local.primary_client_subnet_id

  is_new_keypair_required = false
  keypair_name            = local.existing_keypair_name
}

output "bastion_host_public_ip" {
  value = module.bastion_host.bastion_host_public_ip
}