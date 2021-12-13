variable "vpx_ami_map" {
  description = <<EOF

AMI map for VPX
Defaults to VPX Express 12.1-51.20

EOF

  # Citrix ADC VPX 13.0-83.27 (Oct 22, 2021) image
  default = {
    "us-east-1"      = "ami-0f684afd1827de688"
    "us-east-2"      = "ami-0c8acb930b10701b5"
    "us-west-1"      = "ami-03c9c13ba5319850e"
    "us-west-2"      = "ami-0fdf86c5ff6a6f943"
    "ca-central-1"   = "ami-029b7948b62000522"
    "ap-south-1"     = "ami-09f3fca0ae966dd5f"
    "ap-northeast-1" = "ami-00bfcb562c12ea14e"
    "ap-northeast-2" = "ami-0b1ba7e67baf992fc"
    "ap-southeast-1" = "ami-0e119ee6998148e2f"
    "ap-southeast-2" = "ami-0e2f226c6c787767e"
    "eu-central-1"   = "ami-0d7569522c1683704"
    "eu-north-1"     = "ami-04acd91b4b1b529c4"
    "eu-west-1"      = "ami-036fac39753f28d9e"
    "eu-west-2"      = "ami-049b008d3958a5dd6"
    "eu-west-3"      = "ami-0ab1c3388ec33946c"
    "sa-east-1"      = "ami-057457e9c3ee2ebf6"
  }
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
m5.xlarge
c4.large
c4.xlarge
c4.2xlarge
c4.4xlarge
c4.8xlarge

EOF

  default = "m5.xlarge"
}


variable "vpc_cidr_block" {
  description = "The CIDR block that will be used for all needed subnets"
}

variable "management_subnet_cidr_blocks" {
  description = "The CIDR blocks that will be used for the management subnet. Must be contained inside the VPC cidr block."
  type        = list(string)
}

variable "client_subnet_cidr_blocks" {
  description = "The CIDR blocks that will be used for the client subnet. Must be contained inside the VPC cidr block."
  type        = list(string)
}

variable "server_subnet_cidr_blocks" {
  description = "The CIDR blocks that will be used for the server subnet. Must be contained inside the VPC cidr block."
  type        = list(string)
}

variable "restricted_mgmt_access_cidr_block" {
  description = "The CIDR block of the machines that will SSH into the NSIPs of the VPX HA pair."
}

variable "aws_ssh_key_name" {
  description = "SSH key name stored on AWS EC2 to access EC2 instances"
}

variable "aws_ssh_public_key" {
  sensitive   = true
  description = "The public part of the SSH key you will use to access EC2 instances"
}

variable "aws_region" {
  description = "The AWS region to create entities in."
  default     = "us-east-1"
}

variable "aws_availability_zones" {
  description = "List of two availability zones."
  type        = list(string)
}

variable "aws_access_key" {
  sensitive   = true
  description = "The AWS access key"
}

variable "aws_secret_key" {
  sensitive   = true
  description = "The AWS secret key"
}

variable "internal_lbvserver_vip" {
  description = "LB Vserver VIP for internal apps. This VIP should be  an IP address within the `internal_lbvserver_vip_cidr_block` range"
}

variable "internal_lbvserver_vip_cidr_block" {
  description = "CIDR block for LB Vserver for internal apps. This CIDR block should be outside the VPC CIDR block."
}
