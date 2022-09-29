variable "aws_region" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}

locals {
  region               = var.aws_region
  resource_name_prefix = "tf-test-ha-same-az"

  vpc_cidr = "10.0.0.0/16"

  primary_management_subnet_cidr = "10.0.1.0/24"
  primary_client_subnet_cidr     = "10.0.2.0/24"
  primary_server_subnet_cidr     = "10.0.3.0/24"

  restricted_citrixadc_admin_access_cidr = "106.51.0.0/16"
  citrixadc_admin_password               = "verysecretpassword"
  existing_keypair_name                  = "demo_keypair"


  vpc_id           = "vpc-0888e9f93acce71aa"
  mgmt_subnet_id   = "subnet-079ba4f714037624a"
  client_subnet_id = "subnet-05fb6975086e2463b"
  server_subnet_id = "subnet-03fafbc67aae64180"
}

module "citrixadc_primary" {
  source = "../../modules/aws_citrixadc"

  deploy_prefix = "${local.resource_name_prefix}-primary"

  # AWS Credentials
  aws_region     = var.aws_region
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key

  # Networking
  vpc_cidr                  = local.vpc_cidr
  vpc_id                    = local.vpc_id
  management_subnet_cidr    = local.primary_management_subnet_cidr
  client_subnet_cidr        = local.primary_client_subnet_cidr
  server_subnet_cidr        = local.primary_server_subnet_cidr
  management_subnet_id      = local.mgmt_subnet_id
  client_subnet_id          = local.client_subnet_id
  server_subnet_id          = local.server_subnet_id
  citrixadc_product_version = "13.0"

  # CitrixADC
  restricted_mgmt_access_cidr                          = local.restricted_citrixadc_admin_access_cidr
  citrixadc_admin_password                             = local.citrixadc_admin_password
  is_mgmt_public_ip_required                           = true
  is_client_public_ip_required                         = false
  is_new_keypair_required                              = false
  client_network_interface_secondary_private_ips_count = 1

  keypair_name = local.existing_keypair_name

  citrixadc_firstboot_commands = <<-EOF
    add ns ip ${module.citrixadc_primary.citrixadc_client_network_interface.private_ip_list[1]} ${cidrnetmask(local.primary_client_subnet_cidr)} -type VIP
    add ha node 1 ${module.citrixadc_secondary.citrixadc_management_private_ip}
  EOF

}

resource "aws_eip" "citrixadc_primary_client_network_interface_secondary_private_ip" {
  vpc               = true
  network_interface = module.citrixadc_primary.citrixadc_client_network_interface.id
  tags = {
    "Name" = "${local.resource_name_prefix}-primary-client-network-interface-secondary-private-ip"
  }
}

module "citrixadc_secondary" {
  source = "../../modules/aws_citrixadc"

  # string concat loca.resource_name_prefix with "-secondary"
  deploy_prefix = "${local.resource_name_prefix}-secondary"

  # AWS Credentials
  aws_region     = var.aws_region
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key

  # Networking
  vpc_cidr                  = local.vpc_cidr
  vpc_id                    = local.vpc_id
  management_subnet_cidr    = local.primary_management_subnet_cidr
  client_subnet_cidr        = local.primary_client_subnet_cidr
  server_subnet_cidr        = local.primary_server_subnet_cidr
  management_subnet_id      = local.mgmt_subnet_id
  client_subnet_id          = local.client_subnet_id
  server_subnet_id          = local.server_subnet_id
  citrixadc_product_version = "13.0"

  # CitrixADC
  restricted_mgmt_access_cidr = local.restricted_citrixadc_admin_access_cidr
  citrixadc_admin_password    = local.citrixadc_admin_password

  is_client_public_ip_required = false
  is_new_keypair_required      = false
  keypair_name                 = local.existing_keypair_name

  citrixadc_firstboot_commands = <<-EOF
    shell sleep 60
    add ha node 1 ${module.citrixadc_primary.citrixadc_management_private_ip}
  EOF

  explicit_dependencies = [module.citrixadc_primary]
}
resource "aws_iam_role_policy" "citrix_adc_ha_policy" {
  name = "citrix_adc_ha_policy2"
  role = aws_iam_role.citrix_adc_ha_role.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:AssignPrivateIpAddresses",
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

resource "aws_iam_role" "citrix_adc_ha_role" {
  name = "citrix_adc_ha_role2"
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

resource "aws_iam_instance_profile" "citrix_adc_ha_instance_profile" {
  name = "citrix_adc_ha_instance_profile2"
  path = "/"
  role = aws_iam_role.citrix_adc_ha_role.name
}
