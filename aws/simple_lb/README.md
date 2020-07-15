# Simple Load Balancing setup

This terraform configuration script deploys two Ubuntu Linux images
with an apache server setup that responds to HTTP requests with an
identifying string.

It also uses the terraform citrixadc provider for configuring the
load balancing setup on the target Citrix ADC.

This setup is meant to be used as a quick verification that the
Citrix ADC deployment is working as expected and is not part of
the main Citrix ADC deployment.

The citrixadc terraform provider repository can be found [here](https://github.com/citrix/terraform-provider-netscaler).

## Included files

* `provider_aws.tf`: Setup script for AWS provider.
* `provider_citricadc.tf`: Setup for the Netscaler provider
* `ubuntu.tf`: Setup for the two Ubuntu Linux nodes.
* `lbvserver.tf`: Setup for the Citrix ADC load balancing configuration.
* `variables.tf`: Input variables. These should be populated with values taken from the Citrix ADC deployment.
* `outputs.tf`: Output variables. They contain the management ips of the Ubuntu nodes.
