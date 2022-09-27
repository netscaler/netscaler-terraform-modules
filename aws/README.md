# AWS automation scripts

This folder contains terraform configuration scripts to deploy Citrix ADC on AWS in various deployment scenarios

[Here](https://www.youtube.com/watch?v=LgGS0-Q5ODE&list=PLrUklKi1o_Zny9cgvjJ7xrBtcdOY_Kc6N&index=14&ab_channel=Citrix) is quick demo on using terraform cloud scripts to provision Citrix ADC in AWS.

## 🔐 Authenticating AWS in Terraform

Refer [HERE](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)

## Folder structure

### VPX deployments

The following folders contain configuration scrpts for deploying Citrix ADC instances on AWS in
various configurations.

* `standalone_3nic`: Scripts to deploy a single Citrix ADC instance on AWS with 3 NICs configured.
* `ha_same_az`: Scripts to deploy a Citrix ADC high availability pair in a single AWS availability zone.
* `ha_across_az`:
  * `for_external_apps`: Scripts to deploy a Citrix ADC high availability pair across two AWS availability zones for external apps.
  * `for_internal_apps`: Scripts to deploy a Citrix ADC high availability pair across two AWS availability zones for internal apps.

### Sample service deployments

The following folders contain scripts used to deploy a simple load balancing scheme.

Their purpose is to verify the correct operation of the relevant VPX deployments.

* `simple_lb`: Scripts to deploy a simple load balancing configuration to verify correct network setup of Citrix ADC. Use for testing `standalone_3nic` and `ha_same_az` deployments.
* `simple_lb_across_az`: Scripts to deploy a simple load balancing configuration to verify correct network setup of Citrix ADC. Use for testing `ha_across_az` deployments.

### Various files

The following folders contain various scripts and data files useful for VPX deployments on AWS.

* `scripts`: Helper scripts.


## Use case index

|**Folder**|**Folder Link**|**Description**|
|--|--|--|
|**Deployments**|[HERE](./deployments/cloud_native/)|Cloud Native deployments|
||[HERE](./deployments/standalone_3nic/)|Citrix ADC VPX Standalone 3 nic deployment|
||[HERE](./deployments/ha_same_az/)|Citrix ADC VPX in High Availability within same availability zone|
||[HERE](./deployments/ha_across_az/)|Citrix ADC VPX in High Availability across two availability zones|
|**Examples**|[HERE](./examples/cluster/)|Citrix ADC Cluster configuration|
||[HERE](./examples/simple_lb/)|Citrix ADC deployment with Simple LB configuration within avilanility zones|
||[HERE](./examples/simple_lb_across_az/)|Citrix ADC deployment with Simple LB configuration across availability zones|

# Modules

|**Folder**|**Folder Link**|**Description**|
|--|--|--|
|**Modules**|[HERE](./modules/aws_bastion/)|Terraform module to create a bastion ubuntu host|
||[HERE](./modules/aws_citrixadc/)|Terraform module to provision a standalone 3nic Citrix ADC VPX|
||[HERE](./modules/aws_vpc_infra/)|Terraform module to create required VPC infrastructure for all the deployments|
|**Module Usecases**|[HERE](./modules_usecases/bastion_host/)|Terraform module to create a bastion ubuntu host|
||[HERE](./modules_usecases/standalone_3nic_citrixadc/)|Terraform module example to provision standalone 3nic|
||[HERE](./modules_usecases/ha_same_az/)|Terraform module example to provision VPXs in the same High Availability zone|
||[HERE](./modules_usecases/ha_same_az_existing_vpc/)|Terraform module example to provision VPXs in the same High Availibility zone on the existing VPC infrastructure|
||[HERE](./modules_usecases/ha_across_az/)|Terraform module example to provision VPXs across two High Availability zone|
