resource "null_resource" "setup_ha_pair" {
  provisioner "local-exec" {
    environment = {
      PRIMARY_NODE_PUBLIC_NSIP   = "${element(aws_eip.nsip.*.public_ip, 0)}"
      SECONDARY_NODE_PUBLIC_NSIP = "${element(aws_eip.nsip.*.public_ip, 1)}"

      PRIMARY_NODE_PRIVATE_NSIP   = "${element(aws_network_interface.management.*.private_ip, 0)}"
      SECONDARY_NODE_PRIVATE_NSIP = "${element(aws_network_interface.management.*.private_ip, 1)}"

      PRIMARY_NODE_INSTANCE_ID   = "${element(aws_instance.citrix_adc.*.id, 0)}"
      SECONDARY_NODE_INSTANCE_ID = "${element(aws_instance.citrix_adc.*.id, 1)}"

      PRIMARY_NODE_PRIVATE_VIP   = "${element(aws_network_interface.client.*.private_ip, 0)}"
      SECONDARY_NODE_PRIVATE_VIP = "${element(aws_network_interface.client.*.private_ip, 1)}"

      PRIMARY_NODE_SERVER_SUBNET   = "${cidrhost(element(aws_subnet.server.*.cidr_block, 0), 0)}"
      SECONDARY_NODE_SERVER_SUBNET = "${cidrhost(element(aws_subnet.server.*.cidr_block, 1), 0)}"

      PRIMARY_NODE_SNIP_GW   = "${cidrhost(element(aws_subnet.server.*.cidr_block,0), 1)}"
      SECONDARY_NODE_SNIP_GW = "${cidrhost(element(aws_subnet.server.*.cidr_block,1), 1)}"

      SERVER_SUBNET_MASK = "${var.server_subnet_mask}"

      IPSET_NAME       = "${var.ipset_name}"
      LBVSERVER_NAME   = "${var.lbvserver_name}"
      INITIAL_WAIT_SEC = "${var.initial_wait_sec}"
    }

    interpreter = ["bash"]
    command     = "setup_ha_pair.sh"
  }
}
