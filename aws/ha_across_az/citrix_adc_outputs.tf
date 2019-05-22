output "nsips" {
  value       = "${aws_eip.nsip.*.public_ip}"
  description = "List of the public IP addresses assigned to the management interfaces."
}

output "client_ip" {
  value       = "${aws_eip.client.public_ip}"
  description = "IP address which clients on the data plain will use to access backend services."
}

output "private_vips" {
  value       = "${aws_network_interface.client.*.private_ip}"
  description = "List of the private IP addresses assinged to the client subnet interfaces."
}

output "snips" {
  value       = "${aws_network_interface.server.*.private_ip}"
  description = "List of the private IP addresses assigned to the server subnet interfaces."
}

output "instance_ids" {
  value       = "${aws_instance.citrix_adc.*.id}"
  description = "List of the VPX instances ids."
}

output "private_nsips" {
  value       = "${aws_network_interface.management.*.private_ip}"
  description = "List of the private IP addresses assigned to the management interfaces."
}
