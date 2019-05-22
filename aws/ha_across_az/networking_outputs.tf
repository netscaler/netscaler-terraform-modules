output "client_subnet_ids" {
  value       = "${aws_subnet.client.*.id}"
  description = "List of subnet ids for the client interfaces."
}

output "management_subnet_ids" {
  value       = "${aws_subnet.management.*.id}"
  description = "List of subnet ids for the management interfaces."
}

output "server_subnet_ids" {
  value       = "${aws_subnet.server.*.id}"
  description = "List of subnet ids for the server interfaces."
}

output "server_security_group_id" {
  value       = "${aws_security_group.server.id}"
  description = "Security group id for the server interfaces."
}

output "management_security_group_id" {
  value       = "${aws_security_group.management.id}"
  description = "Security group id for the management interfaces."
}

output "server_subnets_cidr_block" {
  value       = "${aws_subnet.server.*.cidr_block}"
  description = "Cidr blocks of the server subnets."
}
