# Deploy two CitrixADC VPXs in High Availability pair in a single AWS availability zone along with necessary VPC infrastructure.

This folder contains the terraform configuration scripts needed to deploy a Citrix ADC VPX pair on AWS with both instances residing in the same availability zone.

The configuration follows closely the process documented [HERE](https://docs.citrix.com/en-us/citrix-adc/current-release/deploying-vpx/deploy-aws/vpx-aws-ha.html).

At the end of a successful deployment, _inter alia_, the following resources will be deployed.
- 1 VPC
- 3 Subnets - for management, client and server traffic
- 2 CitrixADC VPXs - primary and secondary, configured in High Availability mode
- 6 ENIs - 3 ENIs for each CitrixADC VPXs
- 3 EIPs
  - 2 for accessing CitrixADC VPX management interface
  - 1 for client traffic
- Required security groups, IAM Role etc

## Folder Structure

Refer [HERE](../../../../assets/common_docs/folder_structure.md).

## Usage

Refer [HERE](../../../../assets/common_docs/terraform_usage.md).

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_availability_zone"></a> [aws\_availability\_zone](#input\_aws\_availability\_zone) | Availability zone to create resources in | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region to create things in | `string` | n/a | yes |
| <a name="input_aws_ssh_keypair_name"></a> [aws\_ssh\_keypair\_name](#input\_aws\_ssh\_keypair\_name) | SSH key name stored on AWS EC2 to access EC2 instances | `string` | n/a | yes |
| <a name="input_citrixadc_instance_type"></a> [citrixadc\_instance\_type](#input\_citrixadc\_instance\_type) | CitrixADC VPX EC2 instance type. | `string` | `"m5.xlarge"` | no |
| <a name="input_citrixadc_management_access_cidr"></a> [citrixadc\_management\_access\_cidr](#input\_citrixadc\_management\_access\_cidr) | The CIDR block of the machines that will SSH into the NSIPs of the VPX HA pair. | `string` | n/a | yes |
| <a name="input_citrixadc_management_password"></a> [citrixadc\_management\_password](#input\_citrixadc\_management\_password) | The new ADC password that will replace the default one on both ADC instances. | `string` | n/a | yes |
| <a name="input_citrixadc_product_name"></a> [citrixadc\_product\_name](#input\_citrixadc\_product\_name) | CitrixADC Product Name: Select the product name from the list of available products.<br>  Options:<br>    Citrix ADC VPX - Customer Licensed<br>    Citrix ADC VPX Express - 20 Mbps<br>    Citrix ADC VPX Standard Edition - 10 Mbps<br>    Citrix ADC VPX Standard Edition - 200 Mbps<br>    Citrix ADC VPX Standard Edition - 1000 Mbps<br>    Citrix ADC VPX Standard Edition - 3Gbps<br>    Citrix ADC VPX Standard Edition - 5Gbps<br>    Citrix ADC VPX Premium Edition - 10 Mbps<br>    Citrix ADC VPX Premium Edition - 200 Mbps<br>    Citrix ADC VPX Premium Edition - 1000 Mbps<br>    Citrix ADC VPX Premium Edition - 3Gbps<br>    Citrix ADC VPX Premium Edition - 5Gbps<br>    Citrix ADC VPX Advanced Edition - 10 Mbps<br>    Citrix ADC VPX Advanced Edition - 200 Mbps<br>    Citrix ADC VPX Advanced Edition - 1000 Mbps<br>    Citrix ADC VPX Advanced Edition - 3Gbps<br>    Citrix ADC VPX Advanced Edition - 5Gbps | `string` | `"Citrix ADC VPX - Customer Licensed"` | no |
| <a name="input_citrixadc_product_version"></a> [citrixadc\_product\_version](#input\_citrixadc\_product\_version) | Citrix ADC product version | `string` | `"13.1"` | no |
| <a name="input_citrixadc_rpc_node_password"></a> [citrixadc\_rpc\_node\_password](#input\_citrixadc\_rpc\_node\_password) | The new ADC RPC node password that will replace the default one on both ADC instances. [Learn More about RPCNode](https://docs.citrix.com/en-us/citrix-adc/current-release/getting-started-with-citrix-adc/change-rpc-node-password.html) | `string` | n/a | yes |
| <a name="input_client_subnet_cidr"></a> [client\_subnet\_cidr](#input\_client\_subnet\_cidr) | The CIDR block that will be used for the client subnet. Must be contained inside the VPC cidr block. | `string` | n/a | yes |
| <a name="input_management_subnet_cidr"></a> [management\_subnet\_cidr](#input\_management\_subnet\_cidr) | The CIDR block that will be used for the management subnet. Must be contained inside the VPC cidr block. | `string` | n/a | yes |
| <a name="input_new_keypair_required"></a> [new\_keypair\_required](#input\_new\_keypair\_required) | if `true` (default), terraform creates a new EC2 keypair and associates it to Citrix ADC VPXs. If `false` terraform expects an existing keypair name via `var.aws_ssh_keypair_name` variable | `bool` | `true` | no |
| <a name="input_server_subnet_cidr"></a> [server\_subnet\_cidr](#input\_server\_subnet\_cidr) | The CIDR block that will be used for the server subnet. Must be contained inside the VPC cidr block. | `string` | n/a | yes |
| <a name="input_ssh_public_key_filename"></a> [ssh\_public\_key\_filename](#input\_ssh\_public\_key\_filename) | The public part of the SSH key you will use to access EC2 instances | `string` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block that will be used for all needed subnets | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_citrixadc_client_public_ip"></a> [citrixadc\_client\_public\_ip](#output\_citrixadc\_client\_public\_ip) | IP address which clients on the data plain will use to access backend services. |
| <a name="output_citrixadc_instance_ids"></a> [citrixadc\_instance\_ids](#output\_citrixadc\_instance\_ids) | List of the CitrixADC VPX instances ids. |
| <a name="output_citrixadc_management_public_ips"></a> [citrixadc\_management\_public\_ips](#output\_citrixadc\_management\_public\_ips) | List of the public IP addresses assigned to Primary and Secondary CitrixADC management interfaces. |