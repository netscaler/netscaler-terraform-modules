# AWS Automation Scripts

This folder contains terraform configuration scripts to deploy Citrix ADC on AWS in various deployment scenarios

[Here](https://www.youtube.com/watch?v=LgGS0-Q5ODE&list=PLrUklKi1o_Zny9cgvjJ7xrBtcdOY_Kc6N&index=14&ab_channel=Citrix) is quick demo on using terraform cloud scripts to provision Citrix ADC in AWS.

## 🔐 Authenticating AWS in Terraform

Refer [HERE](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)

## ADC Deployment with Terraform

Users can deploy ADC using Terraform in 2 ways :-
1. Using direct resources
2. Using custom Terraform modules

> For beginners we recommend to go with Resources approach for deployment.

### ADC Deployment and Configuration using Resources

|**Folder**|**Folder Link**|**Description**|
|--|--|--|
|**Deployments**|[HERE](./deployments/cloud_native/)|Cloud Native deployments|
||[HERE](./deployments/standalone_3nic/)|Citrix ADC VPX Standalone 3 nic deployment|
||[HERE](./deployments/ha_same_az/)|Citrix ADC VPX in High Availability within same availability zone|
||[HERE](./deployments/ha_across_az/for_external_apps/)|Citrix ADC VPX in High Availability across two availability zones for External Apps **(Recommended for beginners)**|
||[HERE](./deployments/ha_across_az/for_internal_apps/)|Citrix ADC VPX in High Availability across two availability zones for Internal Apps|
|**Deploy and Config**|[HERE](./deploy_and_config/cluster/)|Citrix ADC Cluster configuration|
||[HERE](./deploy_and_config/simple_lb/)|Citrix ADC deployment with Simple LB configuration within availability zones|
||[HERE](./deploy_and_config/simple_lb_across_az/)|Citrix ADC deployment with Simple LB configuration across availability zones|

### ADC Deployment and Configuration using Modules

|**Folder**|**Folder Link**|**Description**|
|--|--|--|
|**Module Definitions**|[HERE](./modules/aws_bastion/)|Terraform module to create a bastion ubuntu host|
||[HERE](./modules/aws_citrixadc/)|Terraform module to provision a standalone 3nic Citrix ADC VPX|
||[HERE](./modules/aws_vpc_infra/)|Terraform module to create required VPC infrastructure for all the deployments|
|**Modules Usecases**|[HERE](./modules_usecases/bastion_host/)|Terraform module to create a bastion ubuntu host|
||[HERE](./modules_usecases/standalone_3nic_citrixadc/)|Terraform module example to provision standalone 3nic|
||[HERE](./modules_usecases/ha_same_az/)|Terraform module example to provision VPXs in the same High Availability zone|
||[HERE](./modules_usecases/ha_same_az_existing_vpc/)|Terraform module example to provision VPXs in the same High Availability zone on the existing VPC infrastructure|
||[HERE](./modules_usecases/ha_across_az/)|Terraform module example to provision VPXs across two High Availability zone|
