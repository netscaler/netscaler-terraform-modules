# Citrix ADC 3 Network Interface deployment

This folder contains the configuration scripts to deploy
* A Virtual Network with 3 subnets and associated security groups and routing tables.
* A single Citrix ADC instance with 3 NICs.
* A ubuntu bastion host with 1 NIC.

# Resource group

All resources are deployed in a single resource group.

The name of the resource group can be changed through the `resource_group_name` input variable.


# Virtual Network configuration

All network interfaces are deployed inside a single Virtual Network.

There are 3 subnets:

* Managment
* Client
* Server

The Management subnet contains the ADC management interface where the NSIP address is assigned
and the interface of the ubuntu bastion host.

The Client subnet contains the ADC client interface where the VIP address is assigned.

The server subnet contains the ADC server interface where the SNIP is assigned.
Any backed service hosts deployed will need to have an interface defined within this subnet
so that the ADC can communicate with them through the SNIP address.

## Security groups

There are 3 security groups each attached to a single subnet.

The management security group contains a security rule which
allows ssh, http and https inbound traffic
from the controlling subnet.

The controlling subnet can be as restrictive as a single /32 ip address
or as persmissive as 0.0.0.0/0.

The client security group allows http and https access from the internet.

The server security group restricts traffic flow within the subnet itself.
That means network interfaces belonging to this subnet will only be able to
send and receive traffic only to other interfaces inside the subnet.

# Citrix ADC configuration

The Citrix ADC instance is deployed as a single instance with 3 separate
NICs each in a separate subnet. 

The ADC bootstrap code will assign ip addresses to each interface
according to the ip addresses assigned by Azure.

The management network interface is where the NSIP address is asssigned.
There are no additional security rules attached to the interface.
This means that access is only restricted by the subnet attached security group,
which allows access from the controlling subnet for ssh, http and https.

There is a public ip associated with this interface so that it is reachable from
outside the Virtual Network.

For enhanced security one could remove the public ip.
In such case the management interface will only be accessible from within the
Virtual Network.
This means that all ssh connections and NITRO API calls will have to go through
the bastion host.

The client network interface is where the VIP address is assigned.
A public ip address is associated with this interface to allow it to
be reached from the internet.
There are no additional security rules attached to the interface.
This means access is only restricted by the subnet attached security group,
which allows http and https traffic from anywhere.

The server network interface is wherre the SNIP address is assinged.
No public ip address is associated with this interface.
There are no additional security rules attached to the interface.
This means access is only restricted by the subnet attached security group,
which only allows traffic from the subnet itself.

An SSH key is required when creating the ADC host.

Password authentication is also allowed.
Please choose a strong password to enhance security.

# Bastion host

Along with the Citrix ADC an ubuntu bastion host is deployed.

Its role is to provide access to the Virtual Network from
a secured host.

The host requires an SSH key for access.

It has a single network interface which belongs to the management subnet.
As such it can accessed form the controlling subnet.

In case the public ip address associated with the ADC management network interface
is removed the bastion host is the only other way to access the NSIP.

This means all SSH and NITRO API calls will have to be executed from
the bastion host.
