# AWS Provider Configuration

variable "aws_region" {
  description = "The AWS region to create things in"
  default     = "us-east-1"
}

variable "aws_access_key" {
  description = "The AWS access key"
}

variable "aws_secret_key" {
  description = "The AWS secret key"
}

# Citrix ADC Provider Configuration
variable "nsip" {
  description = "The NSIP"
}

variable "username" {
  description = "The username for Citrix ADC"
  default     = "nsroot"
}

variable "instance_id" {
  description = "The default password for Citrix ADC after EC2 instance initialization"
}

# Networking configuration
variable "vip" {
  description = "The Citrix ADC VIP"
}

variable "client_subnet_id" {}

variable "management_subnet_id" {}

# Services configuration
variable "count" {
  description = "The count of backend services"
  default     = 2
}

variable "management_security_group_id" {}
variable "server_security_group_id" {}
variable "server_subnet_id" {}
