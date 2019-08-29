# AWS Related variables
variable "aws_access_key" {
  description = "The AWS access key"
}
variable "aws_secret_key" {
  description = "The AWS secret key"
}
variable "ssh_pub_key" {
  description = "The public part of the SSH key you will use to access EC2 instances"
}
variable "aws_region" {
  description = "The AWS region to create things in"
  default     = "us-east-1"
}
variable "aws_availability_zone" {
  description = "Availability zone to create things in"
  default     = "us-east-1a"
}
variable "key_pair_name" {
  description = "SSH key name stored on AWS EC2 to access EC2 instances"
}
variable "vpc_cidr_block" {
  description = "The CIDR block that will be used for all needed subnets"
}
variable "management_subnet_cidr_block" {
  description = "The CIDR block that will be used for the management subnet. Must be contained inside the VPC cidr block."
}
variable "client_subnet_cidr_block" {
  description = "The CIDR block that will be used for the client subnet. Must be contained inside the VPC cidr block."
}
variable "server_subnet_cidr_block" {
  description = "The CIDR block that will be used for the server subnet. Must be contained inside the VPC cidr block."
}
variable "controlling_subnet" {
  description = "The CIDR block of the machines that will SSH into the NSIPs of the VPX HA pair."
}


# Citrix related variables
variable "initial_num_nodes" {
  description = "Initial number of nodes in the cluster"
  default     = 1
}
variable "vpx_ami_map" {
  description = <<EOF

AMI map for VPX
Defaults to VPX Express 12.1-49.37

EOF

  default = {
    "ap-south-1" = "ami-07d603f6cb021fb9a" # Premium 3Gbps 12.1-53.x
    #TODO: fill in for v12.1-53.x
    /*
    "ap-south-1" = "ami-0d685db0875c12915" # BYOL 12.1-53.x
    "us-east-1" = "ami-01715a94f5a8cb590"
    "us-east-2" = "ami-044ab510df4868644"
    "ap-southeast-2" = "ami-0129a5c095a457b4c"
    "ap-northeast-1" = "ami-0cc1b5d18a331ce3c"
    "sa-east-1" = "ami-06033492560ba1cff"
    "ap-southeast-1" = "ami-0553bb4e1990297b7"
    "ca-central-1" = "ami-06478b9cc5118cab2"
    "ap-northeast-2" = "ami-0b7bcac5c0e9dda2e"
    "us-west-2" = "ami-0c10ec275e28106a8"
    "us-west-1" = "ami-0d7c8111761a1a06c"
    "eu-central-1" = "ami-09fa73854157f8024"
    "eu-west-1" = "ami-012499b628793c2f5"
    "eu-west-2" = "ami-0a2e20b007c7377f9"
*/
  }
}
variable "ns_tenancy_model" {
  description = "Tenancy Type of Citrix ADC Instance"
  default     = "default"
}
variable "ns_instance_type" {
  description = <<EOF
EC2 instance type.

The following values are allowed:

t2.medium
t2.large
t2.xlarge
t2.2xlarge
m3.large
m3.xlarge
m3.2xlarge
m4.large
m4.xlarge
m4.2xlarge
m4.4xlarge
m4.10xlarge
c4.large
c4.xlarge
c4.2xlarge
c4.4xlarge
c4.8xlarge

EOF

  default = "m4.xlarge"
}

variable "cluster_backplane" {
  description = "cluster backplane"
  default = "1/1"
}

variable "cluster_tunnel" {
  description = "cluster tunnel"
  default = "GRE"
}

variable "nodes_password" {
  description = "General password for all the nodes"
  default = "nsroot"
}