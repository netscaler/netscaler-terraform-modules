# Citrix ADC 3 Network Interface deployment

This folder contains the configuration scripts to deploy

* Three networks with associated subnetworks and firewall rules
* A single Citrix ADC instance with 3 NICs one in each of the subnetworks available.

## Input variables

There are input variables defined in several files.

There is a sample variables file in this folder for reference [sample.tfvars](./sample.tfvars).

## Network configuration

There are three networks one for each interface of the Citrix ADC.

* Managment
* Client
* Server

Management network is used to access the NSIP of the ADC and configure it.

The firewall rules will allow for connection from within the network
and the `controlling_subnet` network as defined in the input variables.

Client network is used to access the virtual server that will serve the
content of the backend servers.

The firewall rules will allow access to ports `80` and `443` from
all addresses.

Server network is used to communicate with the backend services.

The firewall rules will allow access for all traffic from within the network.

## Citrix ADC initial configuration

The Citrix ADC instance is configured with only the NSIP address.

Configuration for the VIP and SNIP must be done on the ADC after it has been brought up.

Note that the default password with which the ADC is created, which is the instance id,
must be changed to be able to issue NITRO API calls. 

The ip addresses are present in the output variables of the configuration, `private_vip` and `private_snip`.

Configuration can either be done manually through the ssh connection to the nscli or with
terraform utilizing the `citrixadc_password_resetter` and `citrixadc_nsip` resources of the
citrixadc provider.

To serve client traffic a virtual server must be setup with the VIP as the ip address
and backend services must be configured and bound to it.
