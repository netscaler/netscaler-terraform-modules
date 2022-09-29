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

output "nsips" {
  value       = aws_eip.nsip.*.public_ip
  description = "List of the public IP addresses assigned to the management interfaces."
}

output "private_vips" {
  value       = aws_network_interface.client.*.private_ip
  description = "List of the private IP addresses assinged to the client subnet interfaces."
}

output "snips" {
  value       = aws_network_interface.server.*.private_ip
  description = "List of the private IP addresses assigned to the server subnet interfaces."
}

output "instance_ids" {
  value       = aws_instance.citrix_adc.*.id
  description = "List of the VPX instances ids."
}

output "private_nsips" {
  value       = aws_network_interface.management.*.private_ip
  description = "List of the private IP addresses assigned to the management interfaces."
}

output "primary_server_eni" {
  value       = element(aws_network_interface.server.*.id, 0)
  description = "ENI of the Primary Citrix ADC's Server Interface"
}

output "secondary_server_eni" {
  value       = element(aws_network_interface.server.*.id, 1)
  description = "ENI of the Secondary Citrix ADC's Server Interface"
}
