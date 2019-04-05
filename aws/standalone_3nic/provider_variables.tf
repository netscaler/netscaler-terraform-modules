variable "aws_region" {
  description = "The AWS region to create things in"
  default     = "us-east-1"
}

variable "aws_availability_zone" {
  description = "Availability zone to create things in"
}

variable "aws_access_key" {
  description = "The AWS access key"
}

variable "aws_secret_key" {
  description = "The AWS secret key"
}
