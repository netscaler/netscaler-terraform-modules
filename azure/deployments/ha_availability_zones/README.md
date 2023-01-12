# Citrix ADC HA pair with availability zones

This folder contains the configuration scripts to deploy

* A Virtual Network with 3 subnets and associated security groups and routing tables.
* Two Citrix ADC instances configured in a High Availability setup.
* A ubuntu bastion host with 1 NIC.

## Input Variables

> The file `examples.tfvars` is a variable definition file. This file can be given as an input to `terraform` to define the variables used in the configuration.
> Use below example to load the variables from the file `examples.tfvars`

```bash
terraform apply -var-file="examples.tfvars"
```

> For more information on variable definition files, see [Terraform Variable Definitions](https://www.terraform.io/language/values/variables#variable-definitions-tfvars-files).

```hcl
# file: examples.tfvars
resource_group_name              = "<resource_group_name>"
location                         = "eastus"
virtual_network_address_space    = "10.0.0.0/16"
management_subnet_address_prefix = "10.0.1.0/24"
client_subnet_address_prefix     = "10.0.2.0/24"
server_subnet_address_prefix     = "10.0.3.0/24"
adc_admin_username               = "<adc-username>"
adc_admin_password               = "<adc-password"
ssh_public_key_file              = "~/.ssh/id_rsa.pub"
ubuntu_vm_size                   = "Standard_A1_v2"
ubuntu_admin_user                = "ubuntu"
controlling_subnet               = "<restricted-cidr>" # to login to Citrix ADCs and Ubuntu host
adc_vm_size                      = "Standard_F8s_v2"
ha_for_internal_lb               = false # if true, then Azure ALB will be with public IP. If false, then Azure ALB will be with private IP.
```

## Resource group

All resources are deployed in a single resource group.

The name of the resource group can be changed through the `resource_group_name` input variable.

## Virtual Network configuration

All network interfaces are deployed inside a single Virtual Network.

There are 3 subnets:

* Management
* Client
* Server

The Management subnet contains the ADC management interface where the NSIP address is assigned
and the interface of the ubuntu bastion host.

The Client subnet contains the ADC client interface where the VIP address is assigned.

The server subnet contains the ADC server interface where the SNIP is assigned.
Any backed service hosts deployed will need to have an interface defined within this subnet
so that the ADC can communicate with them through the SNIP address.

### Security groups

There are 3 security groups each attached to a single subnet.

The management security group contains a security rule which
allows ssh, http and https inbound traffic
from the controlling subnet.

The controlling subnet can be as restrictive as a single /32 ip address
or as permissive as 0.0.0.0/0.

The client security group allows http and https access from the internet.

The server security group restricts traffic flow within the subnet itself.
That means network interfaces belonging to this subnet will only be able to
send and receive traffic only to other interfaces inside the subnet.

## Citrix ADC configuration

The Citrix ADC instances are deployed as instances with 3 separate
NICs each in a separate subnet.

The ADC bootstrap code will assign ip addresses to each interface
according to the ip addresses assigned by Azure.

The management network interface is where the NSIP address is assigned.
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
This private VIP address is not used for incoming traffic since we are in an HA setup.

Instead the ip address that will be used for traffic is the public ip address of the
Azure Load Balancer. This address must be assigned to a Vserver (LB/CS) with
functioning backend services. From that point on the ALB public ip address will
start load balancing the instances.
You can find a sample LB configuration in this [folder](../simple_lb_ha)

In the case of a fail over the ALB will detect through the probe one node going down
and the secondary taking over at which point it will starting sending traffic to the
new primary node. Traffic may be impacted for a few seconds until the ALB probe
can determine the functional state of the HA pair.

There are no additional security rules attached to the interface.
This means access is only restricted by the subnet attached security group,
which allows http and https traffic from anywhere.

The server network interface is where the SNIP address is assigned.
No public ip address is associated with this interface.
There are no additional security rules attached to the interface.
This means access is only restricted by the subnet attached security group,
which only allows traffic from the subnet itself.

An SSH key is required when creating the ADC host.

Password authentication is also allowed.
Please choose a strong password to enhance security.

## Bastion host

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
