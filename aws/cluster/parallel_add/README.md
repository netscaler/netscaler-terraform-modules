# Automating Citrix ADC Cluster - for CUSTOMERNAME

The below documentation provides an overview on the provisioning of Citrix ADC clustering using Terraform tool

## Pre-requisities
1. Terraform v.12.0+
2. Space for **two** EIPs in the aws_region


## Folder Structure
### Terraform related files
1. `input.auto.tfvars` - user input file to Terraform
2. `main.tf` - all Terraform resources are present here
3. `variables.tf` - all Terraform variables are declared here
4. `outputs.tf` - all Terraform output variables are declared here

### Python script related files
1. `cluster.py` - used to create and manage cluster. This file will be internally called by Terraform


## Input File `input.auto.tfvars`
// aws authentication

**`aws_access_key`**  =  ""

**`aws_secret_key`**  =  ""

**`ssh_pub_key`**  =  "" // The public key material. Eg., contents of `~/.ssh/id_rsa.pub` file

**`private_key_path`** = "~/.ssh/id_rsa"  // path of the private key

// aws region related inputs

**`aws_region`**  =  "" // default: "us-east-1"

**`aws_availability_zone`**  =  "" // default: "us-east-1a"

// VPC related inputs

**`vpc_cidr_block`**  =  "10.0.0.0/16"

**`management_subnet_cidr_block`**  =  "10.0.1.0/24"

**`client_subnet_cidr_block`**  =  "10.0.2.0/24"

**`server_subnet_cidr_block`**  =  "10.0.3.0/24"

// CitrixADC (node) related inputs

**`ns_instance_type`**  =  "c4.8xlarge" //default: "m4.xlarge" -- Possible Values below

**`ns_tenancy_model`**  =  "default"  # defalut | dedicated

**`nodes_password`**  =  "" #default: "nsroot"

**`key_pair_name`**  =  ""

// Cluster related inputs

**`initial_num_nodes`** =  1  # Max is 32

**`cluster_backplane`**  =  "1/1"

**`cluster_tunnel`**  =  "GRE"

// Modify Cluster

**`modify_cluster`** = false # `true` when modifying(adding more nodes or deleting current nodes) the cluster

### Possible values for `ns_instance_type`
- t2.medium
- t2.large
- t2.xlarge
- t2.2xlarge
- m3.large
- m3.xlarge
- m3.2xlarge
- m4.large
- m4.xlarge
- m4.2xlarge
- m4.4xlarge
- m4.10xlarge
- c4.large
- c4.xlarge
- c4.2xlarge
- c4.4xlarge
- c4.8xlarge

## Assumptions
1. The automation handles only 1 cluster for now
2. All added nodes will go to `state=ACTIVE` by default
3. Adding of nodes will take place **parallely**

## What does the Solution do -
There are two components involved.
- Terraform Tool - which creates the *infrastructure* such as VPC, subnets, required number of CitrixADCs (nodes)
- cluster.py script which helps in managing (add/update/delete) the cluster nodes

### Role of Terraform tool
- Creates a VPC - `Terraform VPC`
- Creates 3 subnets - `management`, `client`, `server`
- Creates 2 security groups - `inside_allow_all`, `outside_world`
- Creates Internet-Gateway - `TR_iGW`
- Creates routing tables - `client_rtb`, `management_rtb`
- Cretees NAT Gatway - `nat_gw`
- Creates ubuntu - `test_ubuntu` - used kind of jumpBox to run `cluster.py` script
- 2 EIPs - one for `test_ubuntu`'s client-side; another for `NAT-GW`
- Role - `citrix_adc_cluster_role`
- 3 ENIs for each CitrixADC - `management`, `server`, `client`
- 2 ENIs for test_ubuntu - `ubuntu_client`, `ubuntu_management`
> Terraform copies `cluster.py` to `test_ubuntu` (acts as jumpBox) and executes it remotely, by passing required arguments.

### Role of `cluster.py` script
- Depending on the arguments, this script adds/updates/deletes the required number of nodes to/from the cluster.

## Limitations, for now
1. Deleting of nodes may have some issues. Please check `Known Issues` section
2. Complete `terraform destroy` may have issues. Refer `Known Issues` for troubleshooting.

## Support in the next release
1. A `prefix` to all the resources created by Terraform so that there can be multiple deployment in the same aws region
2. Taking input of `vpcid` and `subnets` if already present and use them while provisioning Citrix ADCs
3. Stable nodes deletion support
4. Stable `terraform destroy` support

## Known Issues
1. Deleting of nodes might have some issues, specially when more than half of the nodes are being removed from the cluster.
2. `Error: InvalidParameterValue: cannot disassociate the main route table association rtbassoc-0a3627196e28efd35
        status code: 400, request id: d30508a2-858e-4a0a-88ad-f2adece24ca9`
**Solution**: This comes at the time of `terraform destroy`. Manually delete the VPC.
3. Some random error while `terraform apply`
**Solution**:  Delete `teraform.tfstate` file
4. When the `cluster.py` script fails (due to an exception), even when the node is successfully added to the cluster, on the next run the terraform marks these instances as `tainted` and repalace these instances without removing these nodes from the cluster, hence we may have some extra nodes as `UNKNOWN` state.
