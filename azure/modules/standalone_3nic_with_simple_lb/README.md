# Deployment of ADC in standalone 3 NIC with simple lb backend services

This configuration combines the Citrix ADC standalone 3 NIC deployment
with the simple lb backned servers.

The two configurations are configured as modules.

It is meant as a convenience for combining these two deployments
and does not add any new functionality.

## First time creation

Due to the nature of the deployment we need to first
deploy the Citrix ADC to have an NSIP with which to
configure the citrixadc provider in the simple lb module.

To have the configuration applied correctly please run
the following commands in sequence

```
terraform apply -auto-approve -target module.standalone_3nic
terraform apply -auto-approve
```

For convenience there is the `apply.sh` script which
contains this sequence of commands.

Run with

```
bash apply.sh
```
