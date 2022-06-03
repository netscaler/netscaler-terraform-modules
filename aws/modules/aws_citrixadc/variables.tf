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
    "Citrix ADC VPX Express - 20 Mbps" : "daf08ece-57d1-4c0a-826a-b8d9449e3930",
    "Citrix ADC VPX Standard Edition - 10 Mbps" : "85bb75fd-34a4-4395-bb19-04b71b20cf3e",
    "Citrix ADC VPX Standard Edition - 200 Mbps" : "dd84ff86-4cea-4c4b-8811-726d079324c7",
    "Citrix ADC VPX Standard Edition - 1000 Mbps" : "8328715f-8ad4-4121-af6f-77466a6fd325",
    "Citrix ADC VPX Standard Edition - 3Gbps" : "ecde3c83-e3df-4310-931c-be7164f3c504",
    "Citrix ADC VPX Standard Edition - 5Gbps" : "5b010f6b-96e4-4f67-bd66-07022dd5dfec",
    "Citrix ADC VPX Premium Edition - 10 Mbps" : "0f7c03e9-ccf7-4b68-815f-0696e1e5770f",
    "Citrix ADC VPX Premium Edition - 200 Mbps" : "a277a667-7f08-44c9-9787-59424b2c50fa",
    "Citrix ADC VPX Premium Edition - 1000 Mbps" : "198e217b-a775-4322-8bfe-ab1ea7d598f4",
    "Citrix ADC VPX Premium Edition - 3Gbps" : "302979c1-fe98-4344-8a11-c26c88f55e01",
    "Citrix ADC VPX Premium Edition - 5Gbps" : "755645a9-d61f-4350-bb91-a6ef204debb3",
    "Citrix ADC VPX Advanced Edition - 10 Mbps" : "9ff329b9-3273-4ab0-a7db-d1bd714d4bb3",
    "Citrix ADC VPX Advanced Edition - 200 Mbps" : "fff7ca8f-96a9-4ea7-afa1-279b0d23fe3c",
    "Citrix ADC VPX Advanced Edition - 1000 Mbps" : "4e123cf4-fe4c-4afd-a11e-b4280a522de5",
    "Citrix ADC VPX Advanced Edition - 3Gbps" : "d0ebd087-5a71-47e4-8eb0-8bbac8593b43",
    "Citrix ADC VPX Advanced Edition - 5Gbps" : "f67de268-1a70-477e-b135-bf789a9e1d76",
  }
}
variable "citrixadc_product_name" {
  type        = string
  description = <<EOF
  CitrixADC Product Name: Select the product name from the list of available products.
  Options:
    Citrix ADC VPX - Customer Licensed
    Citrix ADC VPX Express - 20 Mbps
    Citrix ADC VPX Standard Edition - 10 Mbps
    Citrix ADC VPX Standard Edition - 200 Mbps
    Citrix ADC VPX Standard Edition - 1000 Mbps
    Citrix ADC VPX Standard Edition - 3Gbps
    Citrix ADC VPX Standard Edition - 5Gbps
    Citrix ADC VPX Premium Edition - 10 Mbps
    Citrix ADC VPX Premium Edition - 200 Mbps
    Citrix ADC VPX Premium Edition - 1000 Mbps
    Citrix ADC VPX Premium Edition - 3Gbps
    Citrix ADC VPX Premium Edition - 5Gbps
    Citrix ADC VPX Advanced Edition - 10 Mbps
    Citrix ADC VPX Advanced Edition - 200 Mbps
    Citrix ADC VPX Advanced Edition - 1000 Mbps
    Citrix ADC VPX Advanced Edition - 3Gbps
    Citrix ADC VPX Advanced Edition - 5Gbps
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