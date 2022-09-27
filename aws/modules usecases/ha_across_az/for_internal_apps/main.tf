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

  internal_lbvserver_vip            = "192.168.1.1"
  internal_lbvserver_vip_cidr_block = "192.168.0.0/16"
}

module "vpc_infra" {
  source = "../../../modules/aws_vpc_infra"

  deploy_prefix = local.resource_name_prefix

  vpc_cidr = local.vpc_cidr

  public_subnets = [
    { cidr = local.primary_client_subnet_cidr, az = "${local.region}a" },
    { cidr = local.secondary_client_subnet_cidr, az = "${local.region}b" },
  ]
  private_subnets = [
    { cidr = local.primary_management_subnet_cidr, az = "${local.region}a" },
    { cidr = local.primary_server_subnet_cidr, az = "${local.region}a" },

    { cidr = local.secondary_management_subnet_cidr, az = "${local.region}b" },
    { cidr = local.secondary_server_subnet_cidr, az = "${local.region}b" },
  ]

  create_nat_gateways = true
}

locals {
  primary_management_subnet_id = module.vpc_infra.private_subnets[0].id
  primary_client_subnet_id     = module.vpc_infra.public_subnets[0].id
  primary_server_subnet_id     = module.vpc_infra.private_subnets[1].id

  secondary_management_subnet_id = module.vpc_infra.private_subnets[2].id
  secondary_client_subnet_id     = module.vpc_infra.public_subnets[1].id
  secondary_server_subnet_id     = module.vpc_infra.private_subnets[3].id

  routing_table_id = module.vpc_infra.public_routing_table.id
}

module "citrixadc_primary" {
  source = "../../../modules/aws_citrixadc"

  deploy_prefix = "${local.resource_name_prefix}-primary"

  # AWS Credentials
  aws_region     = var.aws_region
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key

  # Networking
  vpc_cidr               = module.vpc_infra.vpc_cidr
  vpc_id                 = module.vpc_infra.vpc_id
  management_subnet_cidr = local.primary_management_subnet_cidr
  client_subnet_cidr     = local.primary_client_subnet_cidr
  server_subnet_cidr     = local.primary_server_subnet_cidr
  management_subnet_id   = local.primary_management_subnet_id
  client_subnet_id       = local.primary_client_subnet_id
  server_subnet_id       = local.primary_server_subnet_id

  # CitrixADC
  restricted_mgmt_access_cidr = local.restricted_citrixadc_admin_access_cidr
  citrixadc_admin_password    = local.citrixadc_admin_password
  iam_instance_profile_name   = aws_iam_instance_profile.citrix_adc_haaz_instance_profile.name

  is_mgmt_public_ip_required   = false
  is_client_public_ip_required = false
  is_new_keypair_required      = false

  keypair_name                        = local.existing_keypair_name
  enable_client_eni_source_dest_check = false

  citrixadc_firstboot_commands = <<-EOF
    add ha node 1 ${module.citrixadc_secondary.citrixadc_management_private_ip} -inc ENABLED
    add lb vserver sample_lb_vserver HTTP ${local.internal_lbvserver_vip} 80
  EOF
}

module "citrixadc_secondary" {
  source = "../../../modules/aws_citrixadc"

  deploy_prefix = "${local.resource_name_prefix}-secondary"

  # AWS Credentials
  aws_region     = var.aws_region
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key

  # Networking
  vpc_cidr               = module.vpc_infra.vpc_cidr
  vpc_id                 = module.vpc_infra.vpc_id
  management_subnet_cidr = local.secondary_management_subnet_cidr
  client_subnet_cidr     = local.secondary_client_subnet_cidr
  server_subnet_cidr     = local.secondary_server_subnet_cidr
  management_subnet_id   = local.secondary_management_subnet_id
  client_subnet_id       = local.secondary_client_subnet_id
  server_subnet_id       = local.secondary_server_subnet_id

  # CitrixADC
  restricted_mgmt_access_cidr = local.restricted_citrixadc_admin_access_cidr
  citrixadc_admin_password    = local.citrixadc_admin_password
  iam_instance_profile_name   = aws_iam_instance_profile.citrix_adc_haaz_instance_profile.name

  is_mgmt_public_ip_required   = false
  is_client_public_ip_required = false
  is_new_keypair_required      = false
  keypair_name                 = local.existing_keypair_name

  citrixadc_firstboot_commands = <<-EOF
    shell sleep 120
    add ha node 1 ${module.citrixadc_primary.citrixadc_management_private_ip} -inc ENABLED
  EOF

  explicit_dependencies = [module.citrixadc_primary]
}

resource "aws_iam_role_policy" "citrix_adc_haaz_policy" {
  name = "${local.resource_name_prefix}-citrix_adc_haaz_policy"
  role = aws_iam_role.citrix_adc_haaz_role.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeAddresses",
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
        "ec2:DescribeRouteTables",
        "ec2:DeleteRoute",
        "ec2:CreateRoute",
        "ec2:ModifyNetworkInterfaceAttribute",
        "iam:SimulatePrincipalPolicy",
        "iam:GetRole"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role" "citrix_adc_haaz_role" {
  name = "${local.resource_name_prefix}-citrix_adc_haaz_role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      }
    }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "citrix_adc_haaz_instance_profile" {
  name = "${local.resource_name_prefix}-citrix_adc_haaz_instance_profile"
  path = "/"
  role = aws_iam_role.citrix_adc_haaz_role.name
}

resource "aws_route" "lbvserver_route" {
  route_table_id         = local.routing_table_id
  destination_cidr_block = local.internal_lbvserver_vip_cidr_block
  network_interface_id   = module.citrixadc_primary.citrixadc_client_network_interface.id
  depends_on             = [module.citrixadc_primary]
}

