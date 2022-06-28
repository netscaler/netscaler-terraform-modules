variable "deploy_prefix" {
  type        = string
  description = "The prefix to use for all deployed resources"
}
variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}
variable "restricted_mgmt_access_cidr" {
  type        = string
  description = "CIDR block to restrict access Bastion Host"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_id" {
  type        = string
  description = "Bostion Host Subnet ID"
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