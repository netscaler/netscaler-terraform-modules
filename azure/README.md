# Azure Automation Scripts

This folder contains terraform configuration scripts to deploy Citrix ADC on Microsoft Azure in various deployment scenarios.

## 🔐 Authenticating to Azure in Terraform

Please follow the instructions [HERE](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli)

## How to change Citrix ADC Product in Terraform configuration files?

A complete list of SKUs and Offers for Citrix ADC is available from the below command
> change the `location`, if required

```bash
az vm image list --all --publisher citrix --offer netscalervpx --location eastus --output table
```
Select the appropriate `offer` and `sku` and replace in `storage_image_reference` and `plan` sections of `azure_virtual_machine` resource.

## ADC Deployment with Terraform

Users can deploy ADC using Terraform in 2 ways :-
1. Using direct resources
2. Using custom Terraform modules

> For beginners we recommend to go with Resources approach for deployment.

### ADC Deployment and Configuration using Resources

|**Folder**|**Folder Link**|**Description**|
|--|--|--|
|**Deployments**|[HERE](./deployments/cloud_native/)|Cloud Native deployments|
||[HERE](./deployments/standalone_3nic/)|Citrix ADC VPX Standalone 3 nic deployment on a new VNET infrastructure|
||[HERE](./deployments/standalone_3nic_on_existing_vnet/)|Citrix ADC VPX Standalone 3 nic deployment on an existing VNET infrastructure|
||[HERE](./deployments/ha_availability_set/)|Citrix ADC VPX in High Availability across two availability sets **(Recommended for beginners)**|
||[HERE](./deployments/ha_availability_zones/)|Citrix ADC VPX in High Availability across two availability zones|
||[HERE](./deployments/deploy_adm_agent/)|Deploy Citrix ADM Agent on a new VNET infrastructure|
||[HERE](./deployments/deploy_adm_agent_on_existing_vnet)|Deploy Citrix ADM Agent on an existing VNET infrastructure|
|**Deploy and Config**|[HERE](./deploy_and_config/simple_lb/)|Citrix ADC deployment with Simple LB configuration across availability sets|
||[HERE](./deploy_and_config/simple_lb_ha/)|Citrix ADC deployment with Simple LB configuration across availability zones|

### ADC Deployment and Configuration using Modules

|**Folder**|**Folder Link**|**Description**|
|--|--|--|
|**Module Usecases**|[HERE](./modules/ha_availability_set_with_simple_lb/)|Terraform module example to provisoin VPX in High Avilability across availability sets and a simple LB|
||[HERE](./modules/ha_availability_zones_with_simple_lb/)|Terraform module example to provison VPX in High Availability across availability zones and a simple LB|
||[HERE](./modules/standalone_3nic_with_simple_lb/)|Terraform module example to provision standalone VPX with simple LB|
