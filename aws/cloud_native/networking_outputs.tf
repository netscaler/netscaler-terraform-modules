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

output "client_subnet_ids" {
  value       = aws_subnet.client.*.id
  description = "List of subnet ids for the client interfaces."
}

output "management_subnet_ids" {
  value       = aws_subnet.management.*.id
  description = "List of subnet ids for the management interfaces."
}

output "server_subnet_ids" {
  value       = aws_subnet.server.*.id
  description = "List of subnet ids for the server interfaces."
}

output "server_security_group_id" {
  value       = aws_security_group.server.id
  description = "Security group id for the server interfaces."
}

output "management_security_group_id" {
  value       = aws_security_group.management.id
  description = "Security group id for the management interfaces."
}

output "server_subnets_cidr_block" {
  value       = aws_subnet.server.*.cidr_block
  description = "Cidr blocks of the server subnets."
}

output "vpc_id" {
  value       = aws_vpc.terraform.id
  description = "ID of the VPC that was newly created"
}

