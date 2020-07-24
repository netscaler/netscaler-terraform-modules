output "public_nsip" {
  value = module.standalone_3nic.public_nsip
}

output "private_nsip" {
  value = module.standalone_3nic.private_nsip
}

output "public_vip" {
  value = module.standalone_3nic.public_vip
}

output "private_vip" {
  value = module.standalone_3nic.private_vip
}

output "bastion_public_ip" {
  value = module.standalone_3nic.bastion_public_ip
}

output "private_backend_management_ips" {
  value = module.simple_lb.private_backend_management_ips
}

output "public_backend_management_ips" {
  value = module.simple_lb.public_backend_management_ips
}

output "backend_server_ips" {
  value = module.simple_lb.backend_server_ips
}
