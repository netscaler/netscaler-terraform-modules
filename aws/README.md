# AWS automation scripts

This folder contains terraform configuration scripts to
deploy Citrix ADC on AWS in various deployment scenarios.

## Folder structure

* `standalone_3nic`: Scripts to deploy a single Citrix ADC instance on AWS with 3 NICs configured.
* `simple_lb`: Scripts to deploy a simple load balancing configuration to verify correct network setup of Citrix ADC.
* `ami-maps`: Terraform variables files that contain maps for various Citrix ADC versions.
