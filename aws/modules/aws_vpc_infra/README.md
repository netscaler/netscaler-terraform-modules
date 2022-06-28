



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
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | List of private subnets | `list(map(string))` | n/a | yes |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | List of public subnets | `list(map(string))` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC CIDR | `string` | n/a | yes |
| <a name="input_create_nat_gateways"></a> [create\_nat\_gateways](#input\_create\_nat\_gateways) | (Default: true). Whether to create a NAT gateway | `bool` | `true` | no |

## Resources

| Name | Type |
|------|------|
| [aws_eip.natgw](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/eip) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/nat_gateway) | resource |
| [aws_route.natgw](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/route) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/route_table_association) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/vpc) | resource |

## Example

Check the [examples](examples/) folder for a complete example of how to use this module.

### VPC Subnets in the same Availability Zone

```hcl
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
  citrixadc_admin_password = "verysecretpassword"
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
```

### VPC Subnets in different Availability Zones
```hcl
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
  citrixadc_admin_password = "verysecretpassword"
  existing_keypair_name  = "demo_keypair"
}

module "vpc_infra" {
  source = "../../modules/aws_vpc_infra"

  deploy_prefix = local.resource_name_prefix

  vpc_cidr = local.vpc_cidr

  public_subnets = [
    { cidr = local.primary_management_subnet_cidr, az   = "${local.region}a" },
    { cidr = local.primary_client_subnet_cidr, az   = "${local.region}a" },
    { cidr = local.secondary_management_subnet_cidr, az   = "${local.region}b" },
    { cidr = local.secondary_client_subnet_cidr, az   = "${local.region}b" },
  ]
  private_subnets = [
    { cidr = local.primary_server_subnet_cidr, az   = "${local.region}a" },
    { cidr = local.secondary_server_subnet_cidr, az   = "${local.region}b" },
  ]

  create_nat_gateways = false
}

locals {
  primary_management_subnet_id = module.vpc_infra.public_subnets[0].id
  primary_client_subnet_id     = module.vpc_infra.public_subnets[1].id
  primary_server_subnet_id     = module.vpc_infra.private_subnets[0].id
  secondary_management_subnet_id = module.vpc_infra.public_subnets[2].id
  secondary_client_subnet_id     = module.vpc_infra.public_subnets[3].id
  secondary_server_subnet_id     = module.vpc_infra.private_subnets[1].id
}
```
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | Private Subnets |
| <a name="output_public_routing_table"></a> [public\_routing\_table](#output\_public\_routing\_table) | Public Routing Table |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | Public Subnets |
| <a name="output_vpc_cidr"></a> [vpc\_cidr](#output\_vpc\_cidr) | VPC CIDR |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID |
