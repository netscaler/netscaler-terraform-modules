# Create a Citrix ADC VPX high availability pair across AWS availability zones for internal apps

This folder contains the terraform configuration scripts needed to deploy a Citrix ADC VPX pair on AWS in different availability zone for internal apps.

The configuration follows closely the process documented [here](https://docs.citrix.com/en-us/citrix-adc/12-1/deploying-vpx/deploy-aws/high-availability-different-zones.html).

## Configuration scripts

Following is the description for each configuration scripts

### `provider.df`

This contains the providers initial documentation.
For this deployment, we relay on `aws` provider.

### `main.tf`

This terraform file contains all the resources to be deployed such as `VPC` , `Subnets` , `EC2 instance` , `route-tables` etc

### `variables.tf`

This terraform file contains all the variable declarations required for the deployment

### `outputs.tf`

This terraform file contains the resources output shown after the deployment.

> You can add more outputs as required.

### `input.auto.tfvars`

This is the user config file where you can specify your custom variables.

## How to use these terraform scripts locally

```
git clone https://github.com/citrix/terraform-cloud-scripts.git
cd cd aws/ha_across_az/for_internal_apps
```

* then follow the below steps

### Step1: Modify the `input.auto.tfvars` file

Modify the `input.autoltfvars` as below
| Variable Name   | Usage    |
|--------------- | --------------- |
| `aws_region` | AWS Region of deployment |
| `aws_access_key` | AWS Access Key |
| `aws_secret_key` | AWS secret Key |
| `vpc_cidr_block` | VPC CIDR Block desired |
| `aws_availability_zones` | Availability zones - one for primary Citrix ADC and the other for secondary Citrix ADC |
| `management_subnet_cidr_blocks` | The first CIDR is for first availability zone and second CIDR is for second availability zone |
| `client_subnet_cidr_blocks` | The first CIDR is for first availability zone and second CIDR is for second availability zone |
| `server_subnet_cidr_blocks` | The first CIDR is for first availability zone and second CIDR is for second availability zone |
| `restricted_mgmt_access_cidr_block` | From which IP CIDR you want to reach management access? |
| `aws_ssh_key_name` | SSH key name to be created as per the deployment. Give a new key_name which is not present in your AWS region |
| `aws_ssh_public_key` | File contents of your SSH public key |
| `internal_lbvserver_vip_cidr_block` | VIP CIDR block to serve internal apps |
| `internal_lbvserver_vip` | VIP LB vserver IPv4 address. This IP should be one of the IPs of `internal_lbvserver_vip_cidr_block` |

> `internal_lbvserver_vip_cidr_block` should be outside of `vpc_cidr_block`

### Step2: Terraform flow

After the above step, run the below steps to create and destroy your configuration

1. `terraform init` -- to download the required terraform provider plugins
2. `terraform plan` -- to verify which resources are being added
3. `terraform apply` -- to apply the configuration
4. `terraform destroy` -- to destroy the configuration

> If after first `terraform apply` , you wish to change the configuration, run `terraform apply` again to update your configuration.

### Note

> Citrix ADC version 13.0-83.27 will be deployed.
>
> If you want other images, please change the `ami-id` in `variables.tf` file

## Additional Links

* [Citrix ADC VPX on AWS](https://docs.citrix.com/en-us/citrix-adc/13/deploying-vpx/deploy-aws.html)
* [Deploy a VPX high-availability pair with private IP addresses across different AWS zones](https://docs.citrix.com/en-us/citrix-adc/current-release/deploying-vpx/deploy-aws/vpx-ha-pip-different-aws-zones.html)
* [Citrix ADC HA with private IP now available across multizones in AWS](https://www.citrix.com/blogs/2020/11/03/citrix-adc-ha-with-private-ip-now-available-across-multizones-in-aws/)
* [How High Availability on AWS works](https://docs.citrix.com/en-us/citrix-adc/13/deploying-vpx/deploy-aws/how-aws-ha-works.html)
* [Citrix ADC Overview](https://www.citrix.com/en-in/products/citrix-adc/)
