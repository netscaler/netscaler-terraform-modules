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
  source = "../../../modules/aws_vpc_infra"

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
  restricted_mgmt_access_cidr  = local.restricted_citrixadc_admin_access_cidr
  citrixadc_admin_password     = local.citrixadc_admin_password
  is_mgmt_public_ip_required   = true
  is_client_public_ip_required = true
  is_new_keypair_required      = false
  keypair_name                 = local.existing_keypair_name
  iam_instance_profile_name    = aws_iam_instance_profile.citrix_adc_haaz_instance_profile.name

  citrixadc_firstboot_commands = <<-EOF
    add ns ip ${module.citrixadc_secondary.citrixadc_client_private_ip} ${cidrnetmask(local.secondary_client_subnet_cidr)} -type VIP
    add ha node 1 ${module.citrixadc_secondary.citrixadc_management_private_ip} -inc ENABLED
    add ipset ha_ipset
    bind ipset ha_ipset ${module.citrixadc_secondary.citrixadc_client_private_ip}
    add lb vserver ha_test HTTP ${module.citrixadc_primary.citrixadc_client_private_ip} 80 -ipset ha_ipset
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

  is_mgmt_public_ip_required   = true
  is_client_public_ip_required = false
  is_new_keypair_required      = false
  keypair_name                 = local.existing_keypair_name
  iam_instance_profile_name    = aws_iam_instance_profile.citrix_adc_haaz_instance_profile.name

  citrixadc_firstboot_commands = <<-EOF
    add ha node 1 ${module.citrixadc_primary.citrixadc_management_private_ip} -inc ENABLED
    add ipset ha_ipset
    bind ipset ha_ipset ${module.citrixadc_secondary.citrixadc_client_private_ip}
  EOF

  explicit_dependencies = [module.citrixadc_primary]
}

resource "aws_iam_role_policy" "citrix_adc_haaz_policy" {
  name = "citrix_adc_haaz_policy"
  role = aws_iam_role.citrix_adc_haaz_role.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeAddresses",
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
        "ec2:DescribeInstances",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DetachNetworkInterface",
        "ec2:AttachNetworkInterface",
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:RebootInstances",
        "ec2:AssignPrivateIpAddresses",
        "ec2:UnassignPrivateIpAddresses",
        "autoscaling:*",
        "sns:*",
        "sqs:*",
        "iam:GetRole",
        "iam:SimulatePrincipalPolicy"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role" "citrix_adc_haaz_role" {
  name = "citrix_adc_haaz_role"
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
  name = "citrix_adc_haaz_instance_profile"
  path = "/"
  role = aws_iam_role.citrix_adc_haaz_role.name
}
