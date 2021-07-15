# Create a Cloud Native Deployment with VPX HA across Availability Zones

This folder contains the terraform configuration scripts to bring up a Citrix ADC VPX deployed across different Availability Zones for a Cloud Native Deployment.

The Citrix ADC VPX acts as an Ingress for the AKS or a OpenShift Cluster.

## High Level Configuration Entities created by the Terraform

This folder contains the configuration scripts to deploy
* A Virtual Network with 3 subnets and associated security groups and routing tables.
* Two Citrix ADC instances configured in a High Availability setup.
* A ubuntu bastion host with 1 NIC.

#### Resource group

All resources are deployed in a single resource group.

The name of the resource group can be changed through the `resource_group_name` input variable.


#### Virtual Network configuration

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

#### Security groups

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

#### Citrix ADC configuration

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

#### Bastion host

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

## Explanation of the Input Variables

| Variable                           | Description                          |
| ---------------------------------- | ------------------------------------ |
| `resource_group_name`              | Specify Azure Resource Group Name which will be used for deploying Citrix ADC VPX. |
| `location`                         | Specify Azure Region name to be used for Citrix ADC VPX.                     |
| `virtual_network_address_space`    | Specify the CIDR block to be used for Azure VNet.                            |
| `management_subnet_address_prefix` | Specify the CIDRs for the Management Subnet.                                 |
| `client_subnet_address_prefix`     | Specify the CIDR  for the Client Subnet.                                     |
| `server_subnet_address_prefix`     | Specify the CIDRs for the Server Subnet.                                     |
| `adc_admin_password`               | Password to be configured on Citrix ADC VPX.                                 |
| `controlling_subnet`               | Specify the CIDR which will have access to the deployed Citrix ADC Instances |

## For Kubernetes Cluster

For Cloud Native Deployments where the use case is that a Citrix ADC VPX outside the Kubernetes cluster acts as Ingress, please set the variable `create_ILB_for_management` to `true`

Sample Terraform Variable file below

```
resource_group_name="my-ha-inc-rg"
location="southeastasia"
virtual_network_address_space="192.168.0.0/16"
management_subnet_address_prefix="192.168.0.0/24"
client_subnet_address_prefix="192.168.1.0/24"
server_subnet_address_prefix="192.168.2.0/24"
adc_admin_password="<Provide a strong VPX Password>"
controlling_subnet="<CIDR to allow Management Access>"
```

For more information on Cloud Native Deployments, please see [Citrix Ingress Controller GitHub](https://github.com/citrix/citrix-k8s-ingress-controller)

## For Openshift Cluster

This terraform can also be used to deploy Citrix ADC VPX in HA-INC mode for an OpenShift Cluster. For this you need to provide some additional parameter related to the OpenShift cluster deployed on Azure.

### High Level Additonal Configuration Entities created by the Terraform

#### Networking
1. VNET Peering between VNet of VPX HA and VNet of OpenShift Cluster.
2. Route table and routes for VPX HA to reach pod network of OpenShift Cluster.

#### Citrix ADC
1. Routes in ADC VPX for reaching Openshift worker subnet via Server subnet of VPX HA.
2. Routes in ADC VPX for reaching Openshift pod network via Server subnet of VPX HA.

#### Openshift Cluster
1. Network security rule in Network security group of openshift cluster for allowing traffic from ADC VPX SNIPs.

### High Level Additonal Configuration Entities created by the Bash script.
As the OpenShift cluster is already created by `openshift-installer` before running this terraform, there are few configuration which can't be done with the terraform. For this we have provided one bash script. Please run the bash script after running terraform for doing rest of the required configuration.

Following configuration will be done by Bash script:
1. OpenShift worker and master subnet association with the route table created for HA and pod network of OpenShift.
2. Enables `IP Fordwording` in all the worker node VM's NIC to allow traffic from HA to the pod network of the Openshift Cluster.

For more information on Cloud Native Deployments, please see [Citrix Ingress Controller GitHub](https://github.com/citrix/citrix-k8s-ingress-controller)

### Steps to Deploy:

#### Prerequisites
1. Terraform
2. Azure CLI installed and configured using the command `az login`.
3. Kubernetes configuration utility `kubectl` installed
4. OpenShift Cluster up and running in Azure platform.

#### Clone the GitHub Repo

```
git clone https://github.com/citrix/terraform-cloud-scripts.git
cd terraform-cloud-scripts/terraform-cloud-scripts/azure/ha_availability_zones
```

#### Initialise the terraform deployment

The following is a sample input variable file that contains the input variables to run the entire deployment.

##### Sample Input Variables

```
resource_group_name="priyanka-ha-inc-test"
location="southeastasia"
virtual_network_address_space="1.1.0.0/16"
management_subnet_address_prefix="1.1.1.0/24"
client_subnet_address_prefix="1.1.2.0/24"
server_subnet_address_prefix="1.1.3.0/24"
adc_admin_password="CitrixADC"
controlling_subnet="2.2.2.2"
create_ILB_for_management=true
create_ha_for_openshift=true
openshift_cluster_name = "cnn-oc-cluster-1234"
openshift_cluster_host_network_details={"10.128.2.0/23": "10.0.32.4", "10.129.2.0/23": "10.0.32.5", "10.131.0.0/23": "10.0.32.6"}
```
**Important:** Make sure you input values in the file in accordance with your deployment topology.

##### Explanation of the Additional Input Variables

| Variable                               | Description                          |
| -------------------------------------- | ------------------------------------ |
| create_ILB_for_management              | Enable this to configure ILB whose IP will be used by CIC for configuring Citrix ADC VPX HA |
| create_ha_for_openshift                | Set this to `true` as we are creating HA for OpenShift cluster. |
| openshift_cluster_name                 | Provide Name of you Openshift Cluster deployed in Azure. |
| openshift_cluster_host_network_details | Provide details of Openshift Pod network and node IPs. This should be list of dictionaries and the key for each dictionary will be pod network prefix and value should be OpenShift cluster node IP. |

**Important:** After creating a variable file in accordance with your requirements, ensure to name the file with the suffix `.auto.tfvars`. For example, `my-vpx-ha-deployment.auto.tfvars`

After you create an input variable file, you can initialize the terraform using the following command.

```
terraform init
```

#### Terraform Plan and Apply

```
terraform plan
terraform apply -auto-approve
```

#### Run the bash scipt:
Run the bash scipt for additinal configuration inside the same folder:

```
chmod +x openshift.sh
./openshift.sh
```

## Delete the deployment

The entire deployment can be deleted if needed. Please do this if you absolutely want to delete the complete deployment that includes Citrix ADC VPX HA pair including it's workloads and other Networking elements like Subnets, VPC, VNET Peering etc.

```
./openshift.sh -o delete
terraform refresh
terraform destroy -auto-approve
```

**Note:** `terraform refresh` is needed to make sure terraform updates it's state information correctly so that the destroy happens in a correct order handling the dependencies for each entity.

