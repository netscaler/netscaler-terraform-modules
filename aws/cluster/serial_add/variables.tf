##### General #######
variable "prefix" {
  description = "Prefix string for every created resource"
}
variable "initial_num_nodes" {
  description = "Number[0-32]: Initial number of nodes in the cluster"
}

##### AWS Related variables ######
variable "aws_access_key" {
  description = "The AWS access key"
}
variable "aws_secret_key" {
  description = "The AWS secret key"
}
variable "ssh_pub_key" {
  description = "The public part of the SSH key you will use to access EC2 instances"
}
variable "private_key_path" {
  description = "Path to private key"
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

# Citrix related variables
variable "cco_id" {
  description = "Number[0-32]: The node id of the cluster coordinator. If first run, provide 0, else provide the output of getCCOId.py script. "
}
variable "nodes_password" {
  description = "General password for all the nodes"
}
variable "vpx_ami_map" {
  description = <<EOF

AMI map for VPX
Defaults Citrix ADC (formerly NetScaler) VPX Premium - 10 Mbps

EOF

  default = {
    # Citrix ADC (formerly NetScaler) VPX Premium - 10 Mbps
    "ap-south-1"     = "ami-07d603f6cb021fb9a"
    "us-east-1"      = "ami-0c84f3d6e34c3e140"
    "us-east-2"      = "ami-0c8905815b16eaa5c"
    "ca-central-1"   = "077fe7a442acc5302"
    "ap-southeast-2" = "ami-0df346f7334a1f18c"
    "ap-northeast-1" = "ami-0bba9503faa00868c"
    "sa-east-1"      = "ami-0d199916d27d7b606"
    "ap-southeast-1" = "ami-0ba9e0238292a0a9b"
    "ap-northeast-2" = "ami-0f6cfd3a8e16944f9"
    "us-west-2"      = "ami-0aabd7ee7f758b20e"
    "us-west-1"      = "ami-06a2f5447a8ef7a85"
    "eu-central-1"   = "ami-02c53d5b07ca44f44"
    "eu-west-1"      = "ami-0c8e5a40b4e370a3a"
    "eu-west-2"      = "ami-0a01d60d99fddb534"
  }
}
variable "ubuntu_ami_map" {
  description = <<EOF

AMI map for Ubuntu

EOF

  default = {
    "us-east-1"      = "ami-05fe1f5fe69b3bfbe"
    "us-east-2"      = "ami-09ea854e40f5e0999"
    "us-west-1"      = "ami-09190150221a17211"
    "us-west-2"      = "ami-01e07a87d4cdc78b0"
    "sa-east-1"      = "ami-0079c3d175247b889"
    "eu-north-1"     = "ami-0179f5e5b6e0772bb"
    "eu-west-3"      = "ami-07ae782bdad54acac"
    "eu-west-2"      = "ami-0b72f02c3f22eab2a"
    "eu-west-1"      = "ami-0f7bcea9648e39f82"
    "eu-central-1"   = "ami-0f6e51601337fd2b8"
    "ca-central-1"   = "ami-01a1a64a5396547fe"
    "ap-northeast-1" = "ami-021041b19f6164f68"
    "ap-southeast-2" = "ami-0797654cb4fe8bb5d"
    "ap-southeast-1" = "ami-0ae77a3ed8ad9f591"
    "ap-northeast-2" = "ami-0aa7c6ee4316bc3b8"
    "ap-south-1"     = "ami-08d510acbf36be626"
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
  default     = "1/1"
}
variable "cluster_tunnelmode" {
  description = "cluster tunnelmode"
  default     = "GRE"
}
