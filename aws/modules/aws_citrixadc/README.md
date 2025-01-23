



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
| <a name="input_aws_access_key"></a> [aws\_access\_key](#input\_aws\_access\_key) | The AWS access key. This can also be given as the environment variable `TF_VAR_aws_access_key`. | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region to create things in. (e.g. us-east-1). This can also be given as the environment variable `TF_VAR_aws_region`. | `string` | n/a | yes |
| <a name="input_aws_secret_key"></a> [aws\_secret\_key](#input\_aws\_secret\_key) | The AWS secret key. This can also be given as the environment variable `TF_VAR_aws_secret_key`. | `string` | n/a | yes |
| <a name="input_citrixadc_admin_password"></a> [citrixadc\_admin\_password](#input\_citrixadc\_admin\_password) | CitrixADC Admin Password | `string` | n/a | yes |
| <a name="input_client_subnet_id"></a> [client\_subnet\_id](#input\_client\_subnet\_id) | Client Subnet ID | `string` | n/a | yes |
| <a name="input_deploy_prefix"></a> [deploy\_prefix](#input\_deploy\_prefix) | The prefix to use for all deployed resources | `string` | n/a | yes |
| <a name="input_keypair_name"></a> [keypair\_name](#input\_keypair\_name) | The name of the keypair to use | `string` | n/a | yes |
| <a name="input_management_subnet_id"></a> [management\_subnet\_id](#input\_management\_subnet\_id) | Management Subnet ID | `string` | n/a | yes |
| <a name="input_restricted_mgmt_access_cidr"></a> [restricted\_mgmt\_access\_cidr](#input\_restricted\_mgmt\_access\_cidr) | CIDR block to restrict access to management subnet | `string` | n/a | yes |
| <a name="input_server_subnet_id"></a> [server\_subnet\_id](#input\_server\_subnet\_id) | Server Subnet ID | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `string` | n/a | yes |
| <a name="input__citrixadc_aws_product_map"></a> [\_citrixadc\_aws\_product\_map](#input\_\_citrixadc\_aws\_product\_map) | Map of AWS product names to their product IDs | `map(string)` | <pre>{<br>  "Citrix ADC VPX - Customer Licensed": "63425ded-82f0-4b54-8cdd-6ec8b94bd4f8"<br>}</pre> | no |
| <a name="input_citrixadc_firstboot_commands"></a> [citrixadc\_firstboot\_commands](#input\_citrixadc\_firstboot\_commands) | Commands to run during CitrixADC first boot | `string` | `""` | no |
| <a name="input_citrixadc_instance_type"></a> [citrixadc\_instance\_type](#input\_citrixadc\_instance\_type) | CitrixADC Instance Type | `string` | `"m5.xlarge"` | no |
| <a name="input_citrixadc_product_name"></a> [citrixadc\_product\_name](#input\_citrixadc\_product\_name) | CitrixADC Product Name: Select the product name from the list of available products.<br>  Options:<br>    Citrix ADC VPX - Customer Licensed | `string` | `"Citrix ADC VPX - Customer Licensed"` | no |
| <a name="input_citrixadc_product_version"></a> [citrixadc\_product\_version](#input\_citrixadc\_product\_version) | Citrix ADC product version | `string` | `"13.1"` | no |
| <a name="input_citrixadc_userami"></a> [citrixadc\_userami](#input\_citrixadc\_userami) | AMI image ID to use for the CitrixADC deployment. If this is provided, the AMI image will be used instead of the default latest image. | `string` | `""` | no |
| <a name="input_client_network_interface_secondary_private_ips_count"></a> [client\_network\_interface\_secondary\_private\_ips\_count](#input\_client\_network\_interface\_secondary\_private\_ips\_count) | Number of secondary private IPs to be assigned to the client network interface | `number` | `0` | no |
| <a name="input_client_subnet_cidr"></a> [client\_subnet\_cidr](#input\_client\_subnet\_cidr) | Client subnet CIDR | `string` | `"10.0.2.0/24"` | no |
| <a name="input_enable_client_eni_source_dest_check"></a> [enable\_client\_eni\_source\_dest\_check](#input\_enable\_client\_eni\_source\_dest\_check) | Whether to enable source/destination check for the client network interface | `bool` | `true` | no |
| <a name="input_explicit_dependencies"></a> [explicit\_dependencies](#input\_explicit\_dependencies) | Explicit dependencies | `list` | `[]` | no |
| <a name="input_iam_instance_profile_name"></a> [iam\_instance\_profile\_name](#input\_iam\_instance\_profile\_name) | IAM Instance Profile Name | `string` | `""` | no |
| <a name="input_is_allocate_license"></a> [is\_allocate\_license](#input\_is\_allocate\_license) | (Default: false) true if you want to allocate license, false if you want to use the default license | `bool` | `false` | no |
| <a name="input_is_client_public_ip_required"></a> [is\_client\_public\_ip\_required](#input\_is\_client\_public\_ip\_required) | (Default: false) true if you want to assign a public IP to the client interface, false if you want to use the private IP | `bool` | `false` | no |
| <a name="input_is_mgmt_public_ip_required"></a> [is\_mgmt\_public\_ip\_required](#input\_is\_mgmt\_public\_ip\_required) | (Default: true) true if you want to assign a public IP to the management interface, false if you want to use the private IP | `bool` | `true` | no |
| <a name="input_is_new_keypair_required"></a> [is\_new\_keypair\_required](#input\_is\_new\_keypair\_required) | true if you want to create a new keypair, false if you want to use an existing keypair | `bool` | `true` | no |
| <a name="input_keypair_filepath"></a> [keypair\_filepath](#input\_keypair\_filepath) | The filepath of the SSH public key to use for the keypair to use (if is\_new\_keypair\_required is false) | `string` | `"~/.ssh/id_rsa.pub"` | no |
| <a name="input_license_server_ip"></a> [license\_server\_ip](#input\_license\_server\_ip) | License server IP. Usually it's the ADM Agent IP | `string` | `""` | no |
| <a name="input_management_subnet_cidr"></a> [management\_subnet\_cidr](#input\_management\_subnet\_cidr) | Management subnet CIDR | `string` | `"10.0.1.0/24"` | no |
| <a name="input_pooled_license_bandwidth"></a> [pooled\_license\_bandwidth](#input\_pooled\_license\_bandwidth) | Bandwidth of the license in Mbps | `number` | `0` | no |
| <a name="input_pooled_license_edition"></a> [pooled\_license\_edition](#input\_pooled\_license\_edition) | Pooled License Edition. Possible values: 'Enterprise', 'Standard', 'Platinum' | `string` | `""` | no |
| <a name="input_server_subnet_cidr"></a> [server\_subnet\_cidr](#input\_server\_subnet\_cidr) | Server subnet CIDR | `string` | `"10.0.3.0/24"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC CIDR | `string` | `"10.0.0.0/16"` | no |

## Resources

| Name | Type |
|------|------|
| [aws_eip.client](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/eip) | resource |
| [aws_eip.mgmt](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/eip) | resource |
| [aws_instance.citrix_adc](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/instance) | resource |
| [aws_key_pair.deployer](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/key_pair) | resource |
| [aws_network_interface.client](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/network_interface) | resource |
| [aws_network_interface.management](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/network_interface) | resource |
| [aws_network_interface.server](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/network_interface) | resource |
| [aws_security_group.client](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/security_group) | resource |
| [aws_security_group.management](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/security_group) | resource |
| [aws_security_group.server](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/resources/security_group) | resource |
| [aws_ami.latest](https://registry.terraform.io/providers/hashicorp/aws/4.13.0/docs/data-sources/ami) | data source |

## Example

Check the [examples](examples/) folder for a complete example of how to use this module.

### 3 nic CitrixADC

```hcl

```

### 3 nic CitrixADC with Pooled License
```hcl

```
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_citrixadc_client_network_interface"></a> [citrixadc\_client\_network\_interface](#output\_citrixadc\_client\_network\_interface) | CitrixADC Client Network Interface |
| <a name="output_citrixadc_client_private_ip"></a> [citrixadc\_client\_private\_ip](#output\_citrixadc\_client\_private\_ip) | CitrixADC Client Private IP |
| <a name="output_citrixadc_client_public_ip"></a> [citrixadc\_client\_public\_ip](#output\_citrixadc\_client\_public\_ip) | CitrixADC Client Public IP |
| <a name="output_citrixadc_instance_id"></a> [citrixadc\_instance\_id](#output\_citrixadc\_instance\_id) | CitrixADC Instance ID |
| <a name="output_citrixadc_management_private_ip"></a> [citrixadc\_management\_private\_ip](#output\_citrixadc\_management\_private\_ip) | CitrixADC Management Private IP |
| <a name="output_citrixadc_management_public_ip"></a> [citrixadc\_management\_public\_ip](#output\_citrixadc\_management\_public\_ip) | CitrixADC Management Public IP |
