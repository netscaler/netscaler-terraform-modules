



## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.13.0 |

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 4.13.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deploy_prefix"></a> [deploy\_prefix](#input\_deploy\_prefix) | The prefix to use for all deployed resources | `string` | n/a | yes |
| <a name="input_keypair_name"></a> [keypair\_name](#input\_keypair\_name) | The name of the keypair to use | `string` | n/a | yes |
| <a name="input_restricted_mgmt_access_cidr"></a> [restricted\_mgmt\_access\_cidr](#input\_restricted\_mgmt\_access\_cidr) | CIDR block to restrict access Bastion Host | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Bostion Host Subnet ID | `string` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC CIDR | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `string` | n/a | yes |
| <a name="input_is_new_keypair_required"></a> [is\_new\_keypair\_required](#input\_is\_new\_keypair\_required) | true if you want to create a new keypair, false if you want to use an existing keypair | `bool` | `true` | no |
| <a name="input_keypair_filepath"></a> [keypair\_filepath](#input\_keypair\_filepath) | The filepath of the SSH public key to use for the keypair to use (if is\_new\_keypair\_required is false) | `string` | `"~/.ssh/id_rsa.pub"` | no |

## Resources

| Name | Type |
|------|------|
| [aws_eip.bastion_host](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/eip) | resource |
| [aws_instance.this](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/instance) | resource |
| [aws_key_pair.deployer](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/key_pair) | resource |
| [aws_network_interface.bastion_management](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/network_interface) | resource |
| [aws_security_group.bastion_host](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/security_group) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/data-sources/ami) | data source |

## Example

Check the [examples](examples/) folder for a complete example of how to use this module.

### Single Bastion
```hcl
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
  existing_keypair_name  = "demo_keypair"
}

module "vpc_infra" {
  source = "../../modules/aws_vpc_infra"

  deploy_prefix = local.resource_name_prefix

  vpc_cidr = local.vpc_cidr

  public_subnets = [
    { cidr = local.primary_client_subnet_cidr, az   = "${local.region}a" },
  ]
  private_subnets = [
    { cidr = local.primary_management_subnet_cidr, az   = "${local.region}a" },
    { cidr = local.primary_server_subnet_cidr, az   = "${local.region}a" },
  ]

  create_nat_gateways = false
}

locals {
  vpc_id = module.vpc_infra.vpc_id
  primary_client_subnet_id     = module.vpc_infra.public_subnets[0].id
  primary_management_subnet_id = module.vpc_infra.private_subnets[0].id
  primary_server_subnet_id     = module.vpc_infra.private_subnets[1].id
}

module "bastion_host" {
  source = "../../modules/aws_bastion"

  deploy_prefix = local.resource_name_prefix
  vpc_cidr = local.vpc_cidr
  vpc_id = local.vpc_id
  restricted_mgmt_access_cidr = local.restricted_citrixadc_admin_access_cidr
  subnet_id = local.primary_client_subnet_id

  is_new_keypair_required      = false
  keypair_name = local.existing_keypair_name
}

output "bastion_host_public_ip" {
  value = module.bastion_host.bastion_host_public_ip
}
```
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_host_public_ip"></a> [bastion\_host\_public\_ip](#output\_bastion\_host\_public\_ip) | Public IP of the Bastion Host |
