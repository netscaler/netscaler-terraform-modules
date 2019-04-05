output "management_subnet_id" {
  value = "${aws_subnet.management.id}"
}

output "client_subnet_id" {
  value = "${aws_subnet.client.id}"
}

output "server_subnet_id" {
  value = "${aws_subnet.server.id}"
}

output "default_security_group_id" {
  value = "${aws_default_security_group.default.id}"
}

output "management_security_group_id" {
  value = "${aws_security_group.management.id}"
}

output "client_security_group_id" {
  value = "${aws_security_group.client.id}"
}

output "server_security_group_id" {
  value = "${aws_security_group.server.id}"
}
