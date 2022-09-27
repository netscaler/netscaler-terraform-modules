########################################################################################
#
#  Copyright (c) 2019 Citrix Systems, Inc.
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#      * Redistributions of source code must retain the above copyright
#        notice, this list of conditions and the following disclaimer.
#      * Redistributions in binary form must reproduce the above copyright
#        notice, this list of conditions and the following disclaimer in the
#        documentation and/or other materials provided with the distribution.
#      * Neither the name of the Citrix Systems, Inc. nor the
#        names of its contributors may be used to endorse or promote products
#        derived from this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL Citrix Systems, Inc. BE LIABLE FOR ANY
#  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
########################################################################################

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
  description = "The VIP address of the primary node."
}

variable "client_subnet_id" {
}

variable "management_subnet_id" {
}

# Services configuration
variable "backend_services_count" {
  description = "The count of backend services"
  default     = 2
}

variable "management_security_group_id" {
}

variable "server_security_group_id" {
}

variable "server_subnet_id" {
}

variable "ubuntu_ami_map" {
    type = map(string)
}

variable "aws_ssh_key_name" {}

variable "wait_period" {
  type = number
  default = 120
}

variable "private_ssh_key_path" {
  default = "~/.ssh/id_rsa"
}
