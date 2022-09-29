# AWS related outputs
# output "keypair_aws_key_pair_key_name" {
#   value = aws_key_pair.keypair.key_name
# }

# output "management_aws_subnet_id" {
#   value = aws_subnet.management.id
# }

# output "client_aws_subnet_id" {
#   value = aws_subnet.client.id
# }

# output "server_aws_subnet_id" {
#   value = aws_subnet.server.id
# }

# output "default_aws_default_security_group_id" {
#   value = aws_default_security_group.default.id
# }

# output "management_aws_security_group_id" {
#   value = aws_security_group.management.id
# }

# output "client_aws_security_group_id" {
#   value = aws_security_group.client.id
# }

# output "server_aws_security_group_id" {
#   value = aws_security_group.server.id
# }

# Citrix related outputs
output "citrix_adc_aws_intance_id" {
  value = aws_instance.citrix_adc.*.id
}

output "management_aws_netowrk_interface_private_ip" {
  value = aws_network_interface.management.*.private_ip

}

output "management_aws_network_interface_private_ips" {
  value = aws_network_interface.management.*.private_ips
}

output "public_ip_aws_eip_test_ubuntu" {
  value = aws_eip.test_ubuntu.public_ip
}

# output "server_aws_network_interface_private_ip" {
#   value = aws_network_interface.server.*.private_ip
# }
