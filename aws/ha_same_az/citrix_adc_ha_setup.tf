resource "null_resource" "setup_ha_pair" {


  provisioner  "local-exec" {
    environment = {
	PRIMARY_NODE_PUBLIC_NSIP = "${element(aws_eip.nsip.*.public_ip, 0)}"
	SECONDARY_NODE_PUBLIC_NSIP = "${element(aws_eip.nsip.*.public_ip, 1)}"

	PRIMARY_NODE_PRIVATE_NSIP = "${element(aws_network_interface.management.*.private_ip, 0)}"
	SECONDARY_NODE_PRIVATE_NSIP = "${element(aws_network_interface.management.*.private_ip, 1)}"

	PRIMARY_NODE_INSTANCE_ID = "${element(aws_instance.citrix_adc.*.id, 0)}"
	SECONDARY_NODE_INSTANCE_ID = "${element(aws_instance.citrix_adc.*.id, 1)}"
    }
    interpreter = [ "bash" ]
    command = "setup_ha_nitro.sh"
  }
}
