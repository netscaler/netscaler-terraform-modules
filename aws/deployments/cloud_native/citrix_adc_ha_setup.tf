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

resource "null_resource" "setup_ha_pair" {
  provisioner "local-exec" {
    environment = {
      PRIMARY_NODE_PUBLIC_NSIP     = element(aws_eip.nsip.*.public_ip, 0)
      SECONDARY_NODE_PUBLIC_NSIP   = element(aws_eip.nsip.*.public_ip, 1)
      PRIMARY_NODE_PRIVATE_NSIP    = element(aws_network_interface.management.*.private_ip, 0)
      SECONDARY_NODE_PRIVATE_NSIP  = element(aws_network_interface.management.*.private_ip, 1)
      PRIMARY_NODE_SNIP            = element(aws_network_interface.server.*.private_ip, 0)
      SECONDARY_NODE_SNIP          = element(aws_network_interface.server.*.private_ip, 1)
      PRIMARY_NODE_INSTANCE_ID     = element(aws_instance.citrix_adc.*.id, 0)
      SECONDARY_NODE_INSTANCE_ID   = element(aws_instance.citrix_adc.*.id, 1)
      PRIMARY_NODE_PRIVATE_VIP     = element(aws_network_interface.client.*.private_ip, 0)
      SECONDARY_NODE_PRIVATE_VIP   = element(aws_network_interface.client.*.private_ip, 1)
      PRIMARY_NODE_SERVER_SUBNET   = cidrhost(element(aws_subnet.server.*.cidr_block, 0), 0)
      SECONDARY_NODE_SERVER_SUBNET = cidrhost(element(aws_subnet.server.*.cidr_block, 1), 0)
      PRIMARY_NODE_SNIP_GW         = cidrhost(element(aws_subnet.server.*.cidr_block, 0), 1)
      SECONDARY_NODE_SNIP_GW       = cidrhost(element(aws_subnet.server.*.cidr_block, 1), 1)
      SERVER_SUBNET_MASK           = var.server_subnet_mask
      IPSET_NAME                   = var.ipset_name
      INITIAL_WAIT_SEC             = var.initial_wait_sec
      NEW_PASSWORD                 = var.new_password
      DO_RESET                     = var.reset_password
      CIC_PRIVATE_SNIP             = var.cic_config_snip
      CIC_PRIVATE_SNIP_SUBNET_MASK = "255.255.255.0"
    }

    interpreter = ["bash"]
    command     = "setup_ha_pair.sh"
  }

  depends_on = [aws_instance.citrix_adc]
}
