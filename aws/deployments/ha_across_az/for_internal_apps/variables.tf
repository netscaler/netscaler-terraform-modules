variable "aws_region" {
  type        = string
  description = "The AWS region to create things in"
}

variable "aws_availability_zones" {
  type        = list(string)
  description = "List of 2 availability zones to create resources in. "
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block that will be used for all needed subnets"
}

variable "management_subnet_cidr_list" {
  type        = list(string)
  description = "The CIDR blocks that will be used for the management subnet. Must be contained inside the VPC cidr block."
}

variable "client_subnet_cidr_list" {
  type        = list(string)
  description = "The CIDR blocks that will be used for the client subnet. Must be contained inside the VPC cidr block."
}

variable "server_subnet_cidr_list" {
  type        = list(string)
  description = "The CIDR blocks that will be used for the server subnet. Must be contained inside the VPC cidr block."
}

variable "server_subnet_masks" {
  type        = list(string)
  description = "List of 2 subnet masks for the server networks."
}

variable "citrixadc_instance_type" {
  type        = string
  description = "CitrixADC VPX EC2 instance type."
  default     = "m5.xlarge"
}

variable "citrixadc_management_access_cidr" {
  type        = string
  description = "The CIDR block of the machines that will SSH into the NSIPs of the VPX HA pair."
}

variable "new_keypair_required" {
  type        = bool
  description = "if `true` (default), terraform creates a new EC2 keypair and associates it to Citrix ADC VPXs. If `false` terraform expects an existing keypair name via `var.aws_ssh_keypair_name` variable"
  default     = true
}

variable "aws_ssh_keypair_name" {
  type        = string
  description = "SSH key name stored on AWS EC2 to access EC2 instances"
}

variable "ssh_public_key_filename" {
  type        = string
  description = "The public part of the SSH key you will use to access EC2 instances"
}

variable "citrixadc_management_password" {
  type        = string
  description = "The new ADC password that will replace the default one on both ADC instances."
}

variable "citrixadc_rpc_node_password" {
  type        = string
  description = "The new ADC RPC node password that will replace the default one on both ADC instances. [Learn More about RPCNode](https://docs.citrix.com/en-us/citrix-adc/current-release/getting-started-with-citrix-adc/change-rpc-node-password.html)"
}

variable "citrixadc_product_version" {
  type        = string
  description = "Citrix ADC product version"
  default     = "13.1"
}

variable "_citrixadc_aws_product_map" {
  type        = map(string)
  description = "Map of AWS product names to their product IDs"
  default = {
    "Citrix ADC VPX - Customer Licensed" : "63425ded-82f0-4b54-8cdd-6ec8b94bd4f8",
  }
}
variable "citrixadc_product_name" {
  type        = string
  description = <<EOF
  CitrixADC Product Name: Select the product name from the list of available products.
  Options:
    Citrix ADC VPX - Customer Licensed
  EOF
  default     = "Citrix ADC VPX - Customer Licensed"
}


variable "internal_lbvserver_vip" {
  type        = string
  description = "LB Vserver VIP for internal apps. This VIP should be  an IP address within the `internal_lbvserver_vip_cidr_block` range"
}

variable "internal_lbvserver_vip_cidr_block" {
  type        = string
  description = "CIDR block for LB Vserver for internal apps. This CIDR block should be outside the VPC CIDR block."
}
