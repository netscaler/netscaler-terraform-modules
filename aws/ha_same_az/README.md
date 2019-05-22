# Create a VPX high availability pair in a single AWS availability zone.

This folder contains the terraform configuration scripts needed to
deploy a Citrix ADC VPX pair on AWS with both instances residing in the
same availability zone.

The terraform scripts have been grouped by functionality, so that if
part of the whole functionality is needed you can remove the irrelevant
`.tf` files.

For each `.tf` file there is an accompanying variables and outputs file.
Again this is to group input and output variables that are relevant to
the particular functionality.

The configuration follows closely the process documented [here](https://docs.citrix.com/en-us/citrix-adc/12-1/deploying-vpx/deploy-aws/vpx-aws-ha.html).

## Configuration scripts

Following is the description for each configuration script and the
input and output variables that are defined for it.

### AWS provider configuration

Setup for the AWS provider.

#### Configuration files

* provider.tf
* variables.tf

#### Input variables

* `aws_region`:  The AWS region to create entities in.
* `aws_availability_zones`: List of two availability zones.
* `aws_access_key`: The AWS access key.
* `aws_secret_key`: The AWS secret key.

#### Output variables

None.

### SSH key pair

Create an ssh key pair to access the created VPX instances over SSH.

#### Configuration files

* ssh\_key.tf 
* ssh\_key\_variables.tf

#### Input Variables

* `aws_ssh_key_name` : SSH key name stored on AWS EC2 to access EC2 instances
* `aws_ssh_public_key` :  The public part of the SSH key you will use to access EC2 instances

#### Output variables

None.

### Networking

Creates a VPC, subnets, security groups and routes.

We use a single VPC in which we create the following subnets for each instance.

* management subnet, from which we will allocate NSIPs.
* client subnet, from which we will allocate VIPs.
* server subnet, from which we will allocate SNIPs.

We have an associated security group for each subnet.

The security groups are so defined so that the management subnet is
accessible only from the management subnet and from the controlling
node subnet on all ports.

Client subnet is accessible from the internet on ports 80 and 443.

Server subnet is accessible only from within the server subnet on all ports.

#### Configuration files

* networking.tf
* networking\_variables.tf
* networking\_outputs.tf

#### Input variables

* `vpc_cidr_block`: The CIDR block that will be used for all needed subnets.

* `management_subnet_cidr_block`: The CIDR block that will be used for the management subnet. Must be contained inside the VPC cidr block.
* `client_subnet_cidr_block`: The CIDR block that will be used for the client subnet. Must be contained inside the VPC cidr block.
* `server_subnet_cidr_block`: The CIDR block that will be used for the server subnet. Must be contained inside the VPC cidr block.
* `controlling_subnet`: The CIDR block of the machines that will SSH into the NSIPs of the VPX HA pair.

#### Output variables

* `client_subnet_id`: Subnet id for the client interfaces.
* `management_subnet_id` Subnet id for the management interfaces.
* `server_subnet_id` Subnet id for the server interfaces.
* `default_security_group_id`: Default security group.
* `management_security_group_id` Security group id for the management interfaces.
* `client_security_group_id`: Security group for the client interfaces.
* `server_security_group_id` Security group id for the server interfaces.

### Citrix ADC

Creates the pair of ADC VPX instances that are used to setup the high availability pair.

Note that asssociations between resources is by the index of the resource.

That means if an input variable is a list the first item refers to the first VPX of the pair
and the second item refers to the second VPX of the pair.

The setup only sets up the VPX instances in a single availability zone along with the
networking interfaces setup.

At the end of the script the two instances will be independent of each other.
High availability configuration is handled by a subsequent configuration file.

#### Configuration files

* citrix\_adc.tf
* citrix\_adc\_variables.tf
* citrix\_adc\_outputs.tf

#### Input variables

* `vpx_ami_map`: AMI map for VPX.
* `ns_instance_type`: EC2 instance type.

#### Output variables

* `nsips`: List of the public IP addresses assigned to the management interfaces.
* `client_ip`: IP address which clients on the data plain will use to access backend services.
* `vip`: The private VIP address assinged to the client subnet interface of the primary node.
* `snip`: The private IP addresses assigned to the server subnet interface.
* `instance_ids`: List of the VPX instances ids.
* `private_nsips`: List of the private IP addresses assigned to the management interfaces.


### High availability setup

After creating the VPX instances on AWS a series of configuration steps need
to be made so that they are setup in a high availability pair.

This is handled by a single terraform configuration file along with the
help of a bash script.

We use the `null_resource` to run the `local-exec` provisioner which in turn
runs the bash script.

Environment variables are populated from the input variables and configured resources and
passed to the bash script which uses them.

The bash script uses the `curl` command line tool to make NITRO API requests
to the primary node of the HA VPX pair.

The manual nscli commands which would accomplish the same configuration as the script are detailed below.

```
add ha node 1 <SECONDARY_NODE_PRIVATE_NSIP>

```

On secondary node, (aws\_instance at index 1)

```
add ha node 1 <PRIMARY_NODE_PRIVATE_NSIP>
```
At this point configuration is synced between the two nodes.
As a consequence the `nsroot` user password on the secondary node
becomes the primary node's instance id.

On primary node, (aws\_instance at index 0)
```
save config
```

#### Configuration files 

* citrix\_adc\_ha\_setup.tf 
* citrix\_adc\_ha\_setup\_variables.tf
* setup\_ha\_nitro.sh

#### Input variables

None

#### Output variables

None.
