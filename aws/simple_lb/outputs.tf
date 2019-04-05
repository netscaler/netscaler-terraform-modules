output "management_ips" {
  //value = "${aws_eip.server_management.*.public_ip}"
  value = "${aws_instance.ubuntu.*.public_ip}"
}

output "service_ips" {
  value = "${aws_network_interface.server_data.*.private_ip}"
}
