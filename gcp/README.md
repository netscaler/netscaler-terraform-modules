# Google Cloud Platform Automation Scripts

This folder contains terraform configuration scripts to deploy Citrix ADC on Google Cloud Platform (GCP) in various deployment scenarios.

## 🔐 Authenticating GCP in Terraform

Refer [HERE](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication)

## ADC Deployment with Terraform

The following folders contain configuration scripts for deploying Citrix ADC instances on GCP in various configurations.

### ADC Deployment and Configuration using Resources

|**Folder**|**Folder Link**|**Description**|
|--|--|--|
|**Deployments**|[HERE](./deployments/standalone_3nic/)|Citrix ADC VPX Standalone 3 nic deployment|
||[HERE](./deployments/ha_pair_external_ip/)|Citrix ADC VPX in High Availability deployment with Public VIP and Public NSIP **(Recommended for Beginners)**|
||[HERE](./deployments/ha_pair_external_ip_additional_setup/)|Citrix ADC VPX in High Availability with Public VIP and Public SNIP and deployment with LB vserver|
||[HERE](./deployments/ha_pair_private_ip/)|Citrix ADC VPX im High Availability deployment. No Public VIP and Public NSIP |
||[HERE](./deployments/ha_pair_private_ip_additional_setup/)|Citrix ADC VPX in High Availability deployment with LB vserver. No Public VIP and Public NSIP |
||[HERE](./deployments/ubuntu_host/)|Ubuntu host deployment. This can server as -  <br>1. bastion host to access the NSIP in case no external IP address is associated with the management interface.<br>2. sample backend service by installing and configuring a web server package such as apache2.<br>3. access point for the client interface serving traffic in the case of the VPX deployment with private IP.|
