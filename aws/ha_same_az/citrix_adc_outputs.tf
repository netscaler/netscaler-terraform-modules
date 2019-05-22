output "nsips" {
  description = "List of the public IP addresses assigned to the management interfaces."
  value = "${aws_eip.nsip.*.public_ip}"
}

output "client_ip" {
  description = "IP address which clients on the data plain will use to access backend services."
  value = "${aws_eip.client.public_ip}"
}

output "vip" {
  description = "The private VIP address assinged to the client subnet interface of the primary node."
  value = "${aws_eip.client.private_ip}"
}

output "snip" {
  description = "The private IP addresses assigned to the server subnet interface."
  value = "${aws_network_interface.server.private_ip}"
}

output "instance_ids" {
  description = "List of the VPX instances ids."
  value = "${aws_instance.citrix_adc.*.id}"
}

output "private_nsips" {
  description = "List of the private IP addresses assigned to the management interfaces."
  value = "${aws_network_interface.management.*.private_ip}"
}
