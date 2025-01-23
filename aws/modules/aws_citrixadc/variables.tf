variable "deploy_prefix" {
  type        = string
  description = "The prefix to use for all deployed resources"
}
variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.0.0.0/16"
}
variable "management_subnet_cidr" {
  type        = string
  description = "Management subnet CIDR"
  default     = "10.0.1.0/24"
}

variable "client_subnet_cidr" {
  type        = string
  description = "Client subnet CIDR"
  default     = "10.0.2.0/24"
}
variable "server_subnet_cidr" {
  type        = string
  description = "Server subnet CIDR"
  default     = "10.0.3.0/24"
}
variable "aws_region" {
  type        = string
  description = "The AWS region to create things in. (e.g. us-east-1). This can also be given as the environment variable `TF_VAR_aws_region`."
}

variable "aws_access_key" {
  type        = string
  description = "The AWS access key. This can also be given as the environment variable `TF_VAR_aws_access_key`."
}

variable "aws_secret_key" {
  type        = string
  description = "The AWS secret key. This can also be given as the environment variable `TF_VAR_aws_secret_key`."
}

variable "is_new_keypair_required" {
  description = "true if you want to create a new keypair, false if you want to use an existing keypair"
  type        = bool
  default     = true
}
variable "keypair_name" {
  type        = string
  description = "The name of the keypair to use"
}
variable "keypair_filepath" {
  type        = string
  description = "The filepath of the SSH public key to use for the keypair to use (if is_new_keypair_required is false)"
  default     = "~/.ssh/id_rsa.pub"
}
variable "restricted_mgmt_access_cidr" {
  type        = string
  description = "CIDR block to restrict access to management subnet"
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

variable "citrixadc_admin_password" {
  type        = string
  description = "CitrixADC Admin Password"
  sensitive   = true
}

variable "citrixadc_instance_type" {
  type        = string
  description = "CitrixADC Instance Type"
  default     = "m5.xlarge"
}
variable "is_mgmt_public_ip_required" {
  description = "(Default: true) true if you want to assign a public IP to the management interface, false if you want to use the private IP"
  type        = bool
  default     = true
}
variable "is_client_public_ip_required" {
  description = "(Default: false) true if you want to assign a public IP to the client interface, false if you want to use the private IP"
  type        = bool
  default     = false
}

variable "citrixadc_firstboot_commands" {
  type        = string
  description = "Commands to run during CitrixADC first boot"
  default     = ""
}

variable "citrixadc_userami" {
  type        = string
  description = "AMI image ID to use for the CitrixADC deployment. If this is provided, the AMI image will be used instead of the default latest image."
  default     = ""
  validation {
    condition     = (var.citrixadc_userami == "") || (length(var.citrixadc_userami) > 4 && substr(var.citrixadc_userami, 0, 4) == "ami-")
    error_message = "The image_id value must be a valid AMI id, starting with \"ami-\"."
  }
}

variable "is_allocate_license" {
  description = "(Default: false) true if you want to allocate license, false if you want to use the default license"
  type        = bool
  default     = false
}

variable "license_server_ip" {
  type        = string
  description = "License server IP. Usually it's the ADM Agent IP"
  default     = ""
}

variable "pooled_license_bandwidth" {
  description = "Bandwidth of the license in Mbps"
  type        = number
  default     = 0
  validation {
    condition     = var.pooled_license_bandwidth >= 0
    error_message = "The bandwidth value must be a positive number."
  }
}

variable "pooled_license_edition" {
  type        = string
  description = "Pooled License Edition. Possible values: 'Enterprise', 'Standard', 'Platinum'"
  default     = ""
  validation {
    condition     = contains(["", "Enterprise", "Standard", "Platinum"], var.pooled_license_edition)
    error_message = "Invalid input, Allowed Values: \"Enterprise\", \"Standard\" \"Platinum\"."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "management_subnet_id" {
  type        = string
  description = "Management Subnet ID"
}

variable "client_subnet_id" {
  type        = string
  description = "Client Subnet ID"
}

variable "server_subnet_id" {
  type        = string
  description = "Server Subnet ID"
}

variable "iam_instance_profile_name" {
  type        = string
  description = "IAM Instance Profile Name"
  default     = ""
}

variable "explicit_dependencies" {
  description = "Explicit dependencies"
  type        = list(any)
  default     = []
}
variable "client_network_interface_secondary_private_ips_count" {
  type        = number
  default     = 0
  description = "Number of secondary private IPs to be assigned to the client network interface"
}
variable "enable_client_eni_source_dest_check" {
  type        = bool
  default     = true
  description = "Whether to enable source/destination check for the client network interface"
}