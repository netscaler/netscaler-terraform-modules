# Ubuntu host setup

This folder contains the scripts to deploy an ubuntu host
with three network interfaces.

There is one interface for each of the subnets used by
the HA pair:

* Management
* Client
* Server

The host can be used in a multiple ways.

It can serve as a bastion host to connect to the private NSIP
of the Citrix ADC instances.
This is essential in case the user chooses not to associate
an external ip address with the NSIP interfaces.

It can also serve as a backend service.
By installing and configuring a web server for example
this node can be the backend service referenced by the
HA pair setup scripts.

Lastly it is needed to access the alias VIP address
in the case of the [ha_pair_private_ip/](../ha_pair_private_ip) deployment.

