# Azure automation scripts

This folder contains terraform configuration scripts to
deploy Citrix ADC on Microsoft Azure in various deployment scenarios.

## 🔐 Authenticating to Azure in Terraform

Please follow the instructions [HERE](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli)

## How to change Citrix ADC Product in Terraform configuration files?

A complete list of SKUs and Offers for Citrix ADC is available from the below command
> change the `location`, if required

```bash
az vm image list --all --publisher citrix --offer netscalervpx --location eastus --output table
```
Select the appropriate `offer` and `sku` and replace in `storage_image_reference` and `plan` sections of `azure_virtual_machine` resource.



## Folder structure

### VPX deployments

The following folders contain configuration scripts for deploying Citrix ADC instances on AWS in
various configurations.

* [standalone_3nic](./standalone_3nic): Scripts to deploy a single Citrix ADC instance on Microsoft Azure with 3 NICs configured.
* [ha_availability_set](./ha_availability_set): Scripts to deploy two Citrix ADC instances in High Availability utilizing Azure availability set.
* [ha_availability_zones](./ha_availability_zones): Scripts to deploy two Citrix ADC instances in High Availability utilizing Azure availability zones.

### Sample service deployments

The following folders contain scripts used to deploy a simple load balancing scheme.

Their purpose is to verify the correct operation of the relevant VPX deployments.

* [simple_lb](./simple_lb): Scripts to deploy a simple load balancing configuration to verify correct network setup of Citrix ADC.
Use for testing [standalone_3nic](./standalone_3nic) deployments.
* [simple_lb_ha](./simple_lb_ha): Scripts to deploy a simple load balancing configuration to verify correct network setup of Citrix ADCs in HA mode.
Use for testing [ha_availability_set](./ha_availability_set) and [ha_availability_zones](./ha_availability_zones) deployments.


### Modules combining deployments

The folder `modules` contains terraform modules that combine configurations
present in this folder.

* [modules/standalone_3nic_with_simple_lb](./modules/standalone_3nic_with_simple_lb): Deploy [standalone_3nic](./standalone_3nic) with [simple_lb](./simple_lb)
* [modules/ha_availability_set_with_simple_lb](modules/ha_availability_set_with_simple_lb): Deploy [ha_availability_set](./ha_availability_set) with [simple_lb_ha](./simple_lb_ha)
* [modules/ha_availability_zones_with_simple_lb](modules/ha_availability_zones_with_simple_lb): Deploy [ha_availability_zones](./ha_availability_zones) with [simple_lb_ha](./simple_lb_ha)


## Use case index

|**Folder**|**Folder Link**|**Description**|
|--|--|--|
|**Deployments**|[HERE](./deployments/cloud_native/)|Cloud Native deployments|
||[HERE](./deployments/standalone_3nic/)|Citrix ADC VPX Standalone 3 nic deployment on a new VNET infrastructure|
||[HERE](./deployments/standalone_3nic_on_existing_vnet/)|Citrix ADC VPX Standalone 3 nic deployment on an existing VNET infrastructure|
||[HERE](./deployments/ha_availability_set/)|Citrix ADC VPX in High Availability across two availability sets|
||[HERE](./deployments/ha_availability_zones/)|Citrix ADC VPX in High Availability across two availability zones|
||[HERE](./deployments/deploy_adm_agent/)|Deploy Citrix ADM Agent on a new VNET infrastructure|
||[HERE](./deployments/deploy_adm_agent_on_existing_vnet)|Deploy Citrix ADM Agent on an existing VNET infrastructure|
|**Examples**|[HERE](./examples/simple_lb/)|Citrix ADC deployment with Simple LB configuration across avilanility sets|
||[HERE](./examples/simple_lb_ha/)|Citrix ADC deployment with Simple LB configuration across availability zones|

# Modules

|**Folder**|**Folder Link**|**Description**|
|--|--|--|
|**Module Usecases**|[HERE](./modules/ha_availability_set_with_simple_lb/)|Terraform module example to provisoin VPX in High Avilability across availability sets and a simple LB|
||[HERE](./modules/ha_availability_zones_with_simple_lb/)|Terraform module example to provison VPX in High Availability across availability zones and a simple LB|
||[HERE](./modules/standalone_3nic_with_simple_lb/)|Terraform module example to provision standalone VPX with simple LB|
