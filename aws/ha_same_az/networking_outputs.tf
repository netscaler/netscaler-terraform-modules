output "client_subnet_id" {
  description = "Subnet id for the client interfaces."
  value = "${aws_subnet.client.id}"
}

output "management_subnet_id" {
  description = "Subnet id for the management interfaces."
  value = "${aws_subnet.management.id}"
}

output "server_subnet_id" {
  description = "Subnet id for the server interfaces."
  value = "${aws_subnet.server.id}"
}

output "default_security_group_id" {
  description = "Default security group."
  value = "${aws_default_security_group.default.id}"
}

output "management_security_group_id" {
  description = "Security group id for the management interfaces."
  value = "${aws_security_group.management.id}"
}

output "client_security_group_id" {
  description = "Security group for the client interfaces."
  value = "${aws_security_group.client.id}"
}

output "server_security_group_id" {
  description = "Security group id for the server interfaces."
  value = "${aws_security_group.server.id}"
}

