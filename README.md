# Citrix ADC Terraform scripts for deployment

This repository contains terraform scripts for automating Citrix ADC
deployment on AWS, Azure, GCP and ESX.

The intent is to be utilized as starting points for a more custom configuration
that will match the user's needs.

> :round_pushpin:Learn more about Citrix ADC Automation [here](https://docs.citrix.com/en-us/citrix-adc/current-release/deploying-vpx/citrix-adc-automation.html)

> :round_pushpin:For ADC configurations post deployment , check out [ADC Terraform Provider](https://github.com/citrix/terraform-provider-citrixadc) or [Hashicorp registry](https://registry.terraform.io/providers/citrix/citrixadc/latest)

> :envelope: For any immediate issues or help , reach out to us at appmodernization@citrix.com !

## Terrraform Provider Documentation
1. [Supported Terraform Versions](#supported-terraform-versions)
2. [Navigating the repository](#navigating-the-repository)
3. Use-Case Supported

## Supported terraform versions

The terraform scripts follow the configuration syntax of terraform 0.12.
Note that terraform version 0.12 introduced changes to the configuration syntax
that are not compatible with the previous 0.11 version of terraform.

There exists a `backports` folder which contains the same scripts in configuration
syntax for terraform 0.11.

## Navigating the repository

`aws` contains scripts for AWS automation.

It covers deployment scenarios for AWS.

Currently the following scenarios exist

* Citrix ADC Standalone
* Citrix ADC in a high availability pair in a single AWS availability zone.
* Citrix ADC in a high availability pair across two AWS availability zones.

`backports` contains the same folder structure as the top level directory
but terraform scripts there are in configuration syntax that is valid for
terraform 0.11.

Refer to each folder's README file for more information.
