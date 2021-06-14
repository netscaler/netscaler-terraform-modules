# Create a Cloud Native Deployment with VPX HA across Availability Zones

This folder contains the terraform configuration scripts to bring up a complete Cloud Native Deployment. It brings up an Amazon Managed Kubernetes Cluster (EKS) along with Citrix ADC VPX deployed across different Availability Zone.

The Citrix ADC VPX acts as an Ingress for the EKS cluster.

The terraform scripts have been grouped by functionality, so that if
part of the whole functionality is needed you can remove the irrelevant
`.tf` files.

For each `.tf` file there is an accompanying variables and outputs file.
Again this is to group input and output variables that are relevant to
the particular functionality.

The configuration follows closely the process documented [here](https://docs.citrix.com/en-us/citrix-adc/12-1/deploying-vpx/deploy-aws/high-availability-different-zones.html).

## Sample Input Variables

```
aws_region="ap-south-1"
aws_availability_zones=["ap-south-1a", "ap-south-1b"]
aws_access_key="XXXXXXXXXX"
aws_secret_key="XXXXXXXXXX"
vpc_cidr_block="192.168.0.0/16"
management_subnet_cidr_blocks=["192.168.1.0/24", "192.168.2.0/24"]
client_subnet_cidr_blocks=["192.168.3.0/24", "192.168.4.0/24"]
server_subnet_cidr_blocks=["192.168.5.0/24", "192.168.6.0/24"]
controlling_subnet="17.5.7.8/32"
naming_prefix="cn-terraform"
vpx_ami_map={"ap-south-1"="ami-05db944a73aa7c765"}
ns_instance_type="m4.xlarge"
aws_ssh_key_name="cn-terraform"
aws_ssh_public_key="ssh-rsa XXXXXXXX"
reset_password=true
new_password="My_V3ry_Str0ng_VPX_Passw0rd_!s_Th!5"
cic_config_snip="10.10.10.10"
```

## Terraform Init and Plan

```
terraform init
terraform plan
```

## Terraform Apply

```
terraform apply -auto-approve
```

## See it working

```
$ curl http://$(terraform output -raw frontend_ip) -H "Host: $(terraform output -raw example_application_hostname)"

<html><body><h1>It works!</h1></body></html>
```


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
* `naming_prefix` : The Prefix which will be used in tags of AWS resources. Defaults to "Terraform"

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

We have an associated security group for each category of subnets.

The security groups are so defined so that the management subnets are
accessible only from the management subnets and from the controlling
node subnet on all ports.

Client subnets are accessible from the internet on ports 80 and 443.

Server subnets are accessible only from within the server subnets on all ports.

#### Configuration files

* networking.tf
* networking\_variables.tf
* networking\_outputs.tf

#### Input variables

* `vpc_cidr_block`: The CIDR block that will be used for all needed subnets.
* `management_subnet_cidr_blocks`: The CIDR blocks that will be used for the management subnet. Must be contained inside the VPC cidr block.
* `client_subnet_cidr_blocks`: The CIDR blocks that will be used for the client subnet. Must be contained inside the VPC cidr block.
* `server_subnet_cidr_blocks`: The CIDR blocks that will be used for the server subnet. Must be contained inside the VPC cidr block.
* `controlling_subnet`: The CIDR block of the machines that will SSH into the NSIPs of the VPX HA pair.

#### Output variables

* `client_subnet_ids`: List of subnet ids for the client interfaces.
* `management_subnet_ids` List of subnet ids for the management interfaces.
* `server_subnet_ids` List of subnet ids for the server interfaces.
* `server_security_group_id` Security group id for the server interfaces.
* `management_security_group_id` Security group id for the management interfaces.

### Citrix ADC

Creates the pair of ADC VPX instances that are used to setup the high availability pair.

Note that associations between resources is by the index of the resource.

That means if an input variable is a list the first item refers to the first VPX of the pair
and the second item refers to the second VPX of the pair.

The setup only sets up the VPX instances in the availability zones along with the
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
* `reset_password`: Set to `true` for default password reset.
* `new_password`: The new password.

#### Output variables

* `nsips`: List of the public IP addresses assigned to the management interfaces.
* `frontend_ip`: IP address which clients on the data plane will use to access microservices deployed in Kubernetes cluster
* `private_vips`: List of the private IP addresses assigned to the client subnet interfaces.
* `snips`: List of the private IP addresses assigned to the server subnet interfaces.
* `instance_ids`: List of the VPX instances ids.
* `private_nsips`: List of the private IP addresses assigned to the management interfaces.


### Default password reset

Depending on the ADC version there may exist a policy that will force the
default password to change.

Before this operation no NITRO API call can succeed.

This operation can be turned on or off by the `reset_password` variable.


### High availability setup

After creating the VPX instances on AWS a series of configuration steps need
to be made so that they are setup in a high availability pair.

Additionally some routing configuration needs to be applied on the VPX instances so that
the server interfaces have access to all the server subnets.

This is handled by the ha setup script.

We use the terraform `null_resource` with the `local-exec` provisioner to run the
bash script that does the actual configuration.
Environment variables are populated from the input variables and configured resources and
passed to the bash script which uses them.

The bash script uses the `curl` command line tool to make the NITRO API calls
that ultimately configure the VPX instances in high availability mode.

The manual nscli commands which would accomplish the same configuration as the script are detailed below.

On primary node, (aws\_instance at index 0)

```
add ha node 1 <SECONDARY_NODE_PRIVATE_NSIP> -inc enabled

```

On secondary node, (aws\_instance at index 1)

```
add ha node 1 <PRIMARY_NODE_PRIVATE_NSIP> -inc enabled
```

At this point configuration is synced between the two nodes.
As a consequence the `nsroot` user password on the secondary node
becomes the primary node's instance id.

On primary node, (aws\_instance at index 0)

```
add ipset <IPSET_NAME>
add ns ip <SECONDARY_NODE_PRIVATE_VIP> <SERVER_SUBNET_MASK> -type VIP
bind ipset <IPSET_NAME> <SECONDARY_NODE_PRIVATE_VIP>
add route <SECONDARY_NODE_SERVER_SUBNET> <SERVER_SUBNET_MASK> <PRIMARY_NODE_SNIP_GW>
add ns ip <CIC_PRIVATE_SNIP> <SERVER_SUBNET_MASK> -type SNIP -mgmtAccess ENABLED
```

On secondary node, (aws\_instance at index 1)

```
add ipset <IPSET_NAME>
bind ipset <IPSET_NAME> <SECONDARY_NODE_PRIVATE_VIP>
add route <PRIMARY_NODE_SERVER_SUBNET> <SERVER_SUBNET_MASK> <SECONDARY_NODE_SNIP_GW>
add ns ip <CIC_PRIVATE_SNIP> <SERVER_SUBNET_MASK> -type SNIP -mgmtAccess ENABLED
```

save config
```

At this point a failover will migrate the EIP associated with the primary node's client
interface to the secondary node's client interface.

Notice that backend services setup is not part of this configuration script.

#### Configuration files

* citrix\_adc\_ha\_setup.tf
* citrix\_adc\_ha\_setup\_variables.tf
* setup\_ha\_pair.sh


#### Input variables

* `ipset_name`: Name for the ipset.
* `server_subnet_mask`: Subnet mask for the server network.
*  `initial_wait_sec`: Time interval in seconds to wait before starting the execution of the ha setup script. Should be long enough to allow the ADC to be initialized.

#### Output variables

None.
