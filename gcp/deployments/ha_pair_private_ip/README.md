# Citrix ADC High Availability deployment with private ip address

This folder contains the configuration scripts to deploy

* Three networks with associated subnetworks and firewall rules
* Two Citrix ADC instances configured in a High Availability (HA) setup.

External ip addresses are provided for the NSIP interfaces which
are used to access and configure the HA pair.

The client interface is associated with an alias ip address which
is used to serve backend server traffic.

## Input variables

There are input variables defined in several files.

There is a sample variables file in this folder for reference [sample.tfvars](./sample.tfvars).

## Network configuration

There are three networks one for each interface of the Citrix ADC.

* Managment
* Client
* Server

Management network is used to access the NSIPs of the ADC HA pair and configure it.

The firewall rules will allow for connection from within the network
and the `controlling_subnet` network as defined in the input variables.

Client network is used to access the virtual server that will serve the
content of the backend servers.

The firewall rules will allow access to ports `80` and `443` from
all addresses.

Server network is used to communicate with the backend services.

The firewall rules will allow access for all traffic from within the network.

## Citrix ADC HA pair additional configuration

The initial configuration for the HA pair only includes the HA pair formation
and the NSIP addresses.

Additional configuration must be applied to setup VIP and SNIP addresses as
well as a vserver setup to serve traffic.

The additional configuration needed can be found in this folder
[ha_pair_private_ip_additional_setup](../ha_pair_private_ip_additional_setup).

Please note that before issuing any NITRO API calls to the NSIP of the
primary node the default password, which is the instance id of the primary node, must be changed.

This can be done either interactively from the nscli or using the NITRO
API. The folder [password_reset](../password_reset) contains the configuration
needed for resetting the password using the NITRO API through the terraform 
Citrix ADC provider.
