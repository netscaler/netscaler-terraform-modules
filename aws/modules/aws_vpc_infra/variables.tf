variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}
variable "deploy_prefix" {
  type        = string
  description = "The prefix to use for all deployed resources"
}
variable "public_subnets" {
  type        = list(map(string))
  description = "List of public subnets"
}

variable "private_subnets" {
  type        = list(map(string))
  description = "List of private subnets"
}

variable "create_nat_gateways" {
  type        = bool
  description = "(Default: true). Whether to create a NAT gateway"
  default     = true
}