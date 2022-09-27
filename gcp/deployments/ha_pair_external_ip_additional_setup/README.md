# Citrix ADC High Availability deployment with external ip address additional configuration

This folder contains additional configuration to be
applied after the HA pair has been provisioned.

## Additional setup

The additional setup implemented in this folder will
do the following

* Configure VIP addresses in both HA nodes.
* Configure SNIP addresses in both HA nodes
* Configure an ipset for use with lb vserver
* Configure a sample lb vserver setup with a backend service

The configuration of the lb vserver setup is present
just as an example, to help the user implement his own
service traffic setup.

## Input variables

There are several input variables present in the configuration.

These should be populated with the values taken from the
HA setup scripts in the [ha_pair_external_ip](../ha_pair_external_ip) folder.
