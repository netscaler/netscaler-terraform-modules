output "nsip" {
  value = "${aws_instance.citrix_adc.public_ip}"
}

output "client_ip" {
  value = "${aws_eip.client.public_ip}"
}

output "vip" {
  value = "${aws_eip.client.private_ip}"
}

output "snip" {
  value = "${aws_network_interface.server.private_ip}"
}

output "instance_id" {
  value = "${aws_instance.citrix_adc.id}"
}
