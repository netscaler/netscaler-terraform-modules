output "public_nsips" {
  value = module.ha_availability_set.public_nsips
}

output "private_nsips" {
  value = module.ha_availability_set.private_nsips
}

output "private_vips" {
  value = module.ha_availability_set.private_vips
}

output "bastion_public_ip" {
  value = module.ha_availability_set.bastion_public_ip
}

output "private_backend_management_ips" {
  value = module.simple_lb_ha.private_backend_management_ips
}

output "public_backend_management_ips" {
  value = module.simple_lb_ha.public_backend_management_ips
}

output "backend_server_ips" {
  value = module.simple_lb_ha.backend_server_ips
}

output "alb_public_ip" {
  value = module.ha_availability_set.alb_public_ip
}
