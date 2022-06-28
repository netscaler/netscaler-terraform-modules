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

module "citrixadc_3nic" {
  source = "../../modules/aws_citrixadc"

  deploy_prefix = local.resource_name_prefix

  # AWS Credentials
  aws_region     = var.aws_region
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key

  # Networking
  vpc_cidr = module.vpc_infra.vpc_cidr
  vpc_id   = module.vpc_infra.vpc_id
  # aws_availability_zone  = "ap-south-1a"
  management_subnet_cidr = local.primary_management_subnet_cidr
  client_subnet_cidr     = local.primary_client_subnet_cidr
  server_subnet_cidr     = local.primary_server_subnet_cidr
  management_subnet_id   = module.vpc_infra.public_subnets[0].id
  client_subnet_id       = module.vpc_infra.public_subnets[1].id
  server_subnet_id       = module.vpc_infra.private_subnets[0].id

  # CitrixADC
  # citrixadc_userami            = "" # If this is not set, the default latest AMI will be used.
  restricted_mgmt_access_cidr = local.restricted_citrixadc_admin_access_cidr
  citrixadc_admin_password    = local.citrixadc_admin_password
  # citrixadc_instance_type      = "m5.xlarge"
  # citrixadc_product_name       = "Citrix ADC VPX - Customer Licensed"
  # citrixadc_product_version    = "13.1"
  is_mgmt_public_ip_required   = true
  is_client_public_ip_required = true
  # is_new_keypair_required      = true
  # keypair_filepath             = "~/.ssh/id_rsa"
  keypair_name = "demotf-keypair"

  # CitrixADC License
  # is_allocate_license      = true
  # license_server_ip        = "3.2.4.5"
  # pooled_license_bandwidth = 100
  # pooled_license_edition   = "Platinum"

}
