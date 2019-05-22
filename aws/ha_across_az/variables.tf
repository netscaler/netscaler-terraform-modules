##############################
# AWS Provider configuration #
##############################

variable "aws_region" {
  description = "The AWS region to create entities in."
  default     = "us-east-1"
}

variable "aws_availability_zones" {
  description = "List of two availability zones."
  type        = "list"
}

variable "aws_access_key" {
  description = "The AWS access key"
}

variable "aws_secret_key" {
  description = "The AWS secret key"
}
