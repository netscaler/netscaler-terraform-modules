# AWS automation scripts

This folder contains terraform configuration scripts to
deploy Citrix ADC on AWS in various deployment scenarios.

## Folder structure

### VPX deployments

The following folders contain configuration scrpts for deploying Citrix ADC instances on AWS in
various configurations.

* `standalone_3nic`: Scripts to deploy a single Citrix ADC instance on AWS with 3 NICs configured.
* `ha_same_az`: Scripts to deploy a Citrix ADC high availability pair in a single AWS availability zone.
* `ha_across_az`: Scripts to deploy a Citrix ADC high availability pair across two AWS availability zones.

### Sample service deployments

The following folders contain scripts used to deploy a simple load balancing scheme.

Their purpose is to verify the correct operation of the relevant VPX deployments.

* `simple_lb`: Scripts to deploy a simple load balancing configuration to verify correct network setup of Citrix ADC. Use for testing `standalone_3nic` and `ha_same_az` deployments.
* `simple_lb_across_az`: Scripts to deploy a simple load balancing configuration to verify correct network setup of Citrix ADC. Use for testing `ha_across_az` deployments.

### Various files

The following folders contain various scripts and data files useful for VPX deployments on AWS.

* `ami-maps`: Terraform variables files that contain maps for various Citrix ADC versions.
* `scripts`: Helper scripts.
