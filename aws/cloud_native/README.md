# Create a Cloud Native Deployment with VPX HA across Availability Zones

This folder contains the terraform configuration scripts to bring up a complete Cloud Native Deployment. It brings up an Amazon Managed Kubernetes Cluster (EKS) along with Citrix ADC VPX deployed across different Availability Zones.

The Citrix ADC VPX acts as an Ingress for the EKS cluster.

The terraform scripts have been grouped by functionality, so that if
a part of the whole functionality is not needed you can remove the irrelevant
`.tf` files.

For each `.tf` file there is an accompanying variables and outputs file.
Again, this is to group input and output variables that are relevant to
the particular functionality.

The configuration combines the process documented for [Deploying VPX HA with Private IP addresses](https://docs.citrix.com/en-us/citrix-adc/current-release/deploying-vpx/deploy-aws/vpx-ha-pip-different-aws-zones.html) and [Deploying VPX HA with Elastic IP addresses](https://docs.citrix.com/en-us/citrix-adc/current-release/deploying-vpx/deploy-aws/vpx-ha-eip-different-aws-zones.html).

## High Level Configuration Entities created by the Terraform

#### Networking 
1. VPC with 6 Subnets in 2 Availability Zones
    * 2 Client Network Subnets
    * 2 Management Network Subnets
    * 2 Server Network Subnets
2. NAT gateway for Outbound Internet traffic for Server Network Subnets
3. Internet Gateway for Inbound Internet traffic for Client Network Subnets
4. Security Groups for all the created Subnets
5. Route Table for Citrix Ingress Controller to configure the Citrix ADC. For more information, read [Deploying VPX HA with Private IP addresses](https://docs.citrix.com/en-us/citrix-adc/current-release/deploying-vpx/deploy-aws/vpx-ha-pip-different-aws-zones.html)
6. Allocate and assign Elastic IP for Citrix ADC VIP

### Citrix ADC 
1. Primary Citrix ADC and Secondary Citrix ADC are deployed in 3-NIC mode
2. Nitro Configuration on Citrix ADC includes:
    * Setting up HA INC mode between the ADCs and other required network configuration like SNIP, VIP, etc.
    * IPSET configuration on Citrix ADC. This will be used by Citrix Ingress Controller in the Frontend configuration.
    * Static Routes to reach Kubernetes PODS in other Availability Zones.
    * RESET the default Citrix ADC password
    * Private SNIP configuration on the Citrix ADC which will be used by Citrix Ingress Controller for Configuration.

### EKS
1. An EKS cluster spanning across multiple Availability Zones with a configurable worker node group.
2. Security Groups to allow traffic from Citrix ADC HA pair to EKS cluster and vice versa.

### Kubernetes
1. Deploy a Citrix Ingress Controller using HELM charts
    * All the required input parameters will be automatically parsed from the Terraform scripts itself. There is zero manual intervention when deploying Citrix Ingress Controller.
2. Kubernetes Secret for Citrix ADC login. This will be used by Citrix Ingress Controller for ADC configuration.
3. Deploy a sample apache microservice and expose it as a Kubernetes Service
4. Expose the Apache microservice application to public using Citrix ADC HA pair by creating an Ingress configuration.

## Steps to Deploy:

### Prerequisites
1. Terraform (preferably version: `1.1.7`)
2. AWS CLI installed and configured using the command `aws configure`.
3. Kubernetes configuration utility `kubectl` installed

**Important Note:** These terraform deployments were validated on Terraform Version: `1.1.7`. Please ensure you install terraform version: `1.1.7`.

### Clone the GitHub Repo

```
git clone https://github.com/citrix/terraform-cloud-scripts.git
cd terraform-cloud-scripts/aws/cloud_native
```

### Initialise the terraform deployment

As mentioned earlier in the document, this folder contains many `.tf` scripts and they are split based on the functionality.
Each functionality has it's own `input variables` and `output variables`. They have their own default values too.

However, there are some mandatory `input variables` that needs to be specified to create the deployment.

The following is a sample input variable file that contains the bare minimum input variables to run the entire deployment.

### Sample Input Variables

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
vpx_ami_map={"ap-south-1"="ami-09f3fca0ae966dd5f"}
ns_instance_type="m4.xlarge"
aws_ssh_key_name="cn-terraform"
aws_ssh_public_key="ssh-rsa XXXXXXXX"
reset_password=true
new_password="My_V3ry_Str0ng_VPX_Passw0rd_!s_Th!5"
cic_config_snip="10.10.10.10"
```

#### Explanation of the Input Variables

| Variable                        | Description                                                                                                                |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `aws_region`                    | Specify the AWS region                                                                                                     |
| `aws_availability_zones`        | Specify the availability zones to be used in the region. This should in a `list` format                                    |
| `aws_access_key`                | Specify the AWS Access Key                                                                                                 |
| `aws_secret_key`                | Specify the AWS Secret Key                                                                                                 |
| `vpc_cidr_block`                | Specify the CIDR block to be used for the VPC                                                                              |
| `management_subnet_cidr_blocks` | Specify the CIDRs for the Management Subnet. This should in a `list` format                                                |
| `client_subnet_cidr_blocks`     | Specify the CIDRs for the Client Subnet. This should in a `list` format                                                    |
| `server_subnet_cidr_blocks`     | Specify the CIDRs for the Server Subnet. This should in a `list` format                                                    |
| `controlling_subnet`            | Specify the CIDR which will have access to the deployed Citrix ADC Instances                                               |
| `naming_prefix`                 | (Optional) Specify a name which will be prefixed in all the created resource names                                         |
| `vpx_ami_map`                   | Specify the AMI map for Citrix ADC VPX                                                                                     |
| `ns_instance_type`              | Specify the Citrix ADC Instance type                                                                                       |
| `aws_ssh_key_name`              | Specify the AWS SSH key name                                                                                               |
| `aws_ssh_public_key`            | Specify the SSH Public key to use                                                                                          |
| `reset_password`                | Specify if the Citrix ADC Password has to be resetted. Set this to `true` always.                                          |
| `new_password`                  | Specify a strong Citrix ADC VPX Password                                                                                   |
| `cic_config_snip`               | Specify an IP that will be used as SNIP in the Citrix ADC. This IP should be outside the VPC CIDR range (`vpc_cidr_block`) |

Make sure you input values in the file in accordance with your deployment topology.

**Important:** After creating a variable file in accordance with your requirements, ensure to name the file with the suffix `.auto.tfvars`. For example, `my-vpx-ha-deployment.auto.tfvars`

After you create an input variable file, you can initialize the terraform using the following command.

```
terraform init
```

## Terraform Plan and Apply

```
terraform plan
terraform apply -auto-approve
```

## See it working

The terraform would take a few minutus to complete. Once the terraform execution completes, you can see things in action by using a simple `curl` command.

```
curl http://$(terraform output -raw frontend_ip) -H "Host: $(terraform output -raw example_application_hostname)"
```

Response:

```
<html><body><h1>It works!</h1></body></html>
```

This response we see from the `curl` command is the response from the Apache Microservice that is deployed inside the EKS cluster.

The Citrix ADC VPX HA pair has load-balanced the HTTP request to the Apache microservice and relayed the response back.

This is just a simple example on how to expose a microserivce using Citrix ADC VPX HA pair as Ingress. You can leverage the same for your microservice applications. You can also use the advanced features of Citrix Ingress Controller like SSL Termination, URL rewrite, Application Security, etc.

For more information on Citrix Ingress Controller, read [Citrix Ingress Controller](https://developer-docs.citrix.com/projects/citrix-k8s-ingress-controller/en/latest/)

## Using `kubectl` to see the deployed Workloads in EKS

To have a look at the payloads that the terraform deployed on EKS, use the following command to download the `kubeconfig` of the newly created EKS cluster. This `kubeconfig` file would be saved to the default `kubeconfig` location.

To know the default name of the EKS cluster, have a look at the variable `cluster_name` in the `eks_variables.tf` file.

```
aws eks --region $(terraform output --raw aws_region) update-kubeconfig --name $(terraform output --raw cluster_name)
```

After this, you can use the regular `kubectl` commands to see the workloads and other configuration in the EKS cluster.

## Delete the entire deployment

The entire deployment can be deleted if needed. Please do this if you absolutely want to delete the complete deployment that includes Citrix ADC VPX HA pair, EKS cluster including it's workloads and other Networking elements like Subnets, VPC, etc.

```
terraform refresh
terraform destroy -auto-approve
```

**Note:** `terraform refresh` is needed to make sure terraform updates it's state information correctly so that the destroy happens in a correct order handling the dependencies for each entity.


More information on the Terraform scripts can be found [here](https://github.com/citrix/terraform-cloud-scripts/blob/master/aws/ha_across_az/README.md)
