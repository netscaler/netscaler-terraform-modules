# Citrix ADC Terraform automation scripts

This repository contains terraform scripts for automating Citrix ADC
deployment on cloud services, such as AWS and Azure.

The intent is to be utilized as starting points for a more custom configuration
that will match the user's needs.

## Folder structure

`aws` contains scripts for AWS automation.

It covers deployment scenarios for AWS.

Currently the following scenarios exist

* Citrix ADC Standalone
* Citrix ADC in a high availability pair in a single AWS availability zone.
* Citrix ADC in a high availability pair across two AWS availability zones.

Refer to each folder's README file for more information.
