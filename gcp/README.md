# Google Cloud Platform automation scripts

This folder contains terraform configuration scripts to
deploy Citrix ADC on Google Cloud Platform (GCP) in various
deployment scenarios.

## 🔐 Authenticating GCP in Terraform

Refer [HERE](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication)


## Folder structure

### VPX deployments

The following folders contain configuration scripts for deploying Citrix ADC instances on GCP in
various configurations.

* [standalone_3nic](./standalone_3nic): Scripts to deploy a single Citrix ADC instance on GCP with 3 NICs configured.
* [ha_pair_external_ip](./ha_pair_external_ip): Scripts to deploy two Citrix ADC instances in High Availability using an external static ip address associated with the client interface that will serve traffic.
* [ha_pair_private_ip/](./ha_pair_private_ip): Scripts to deploy two Citrix ADC instances in High Availability using a private alias ip address associated with the client interface that will serve traffic.

### Additional Configuration

The following folders contain additional configuration scripts for the HA pair deployment.

* [ha_pair_external_ip_additional_setup](./ha_pair_external_ip_additional_setup): Scripts to add VIP, SNIP addresses and a sample lb setup for the [ha_pair_external_ip](./ha_pair_external_ip) VPX deployment.

* [ha_pair_private_ip_additional_setup](./ha_pair_private_ip_additional_setup): Scripts to add VIP, SNIP addresses and a sample lb setup for the [ha_pair_private_ip/](./ha_pair_private_ip) VPX deployment.

* [password_reset](./password_reset): Script to reset the default password for the HA pair.


### Additional service deployments

The following folders contain scripts to deploy additional virtual machines for utility pursposes.

* [ubuntu_host](./ubuntu_host): Scripts to deploy an ubuntu vm with three interfaces one on each VPX utilized subnets.

    It can serve as a bastion host to access the NSIP in case no external ip address is associated with the management interface.

    It can also serve as a sample backend service by installing and configuring a web server package (e.g. apache2).

    Additionally it can serve as an access point for the client interface serving traffic in the case of the VPX deployment with
    private ip.
