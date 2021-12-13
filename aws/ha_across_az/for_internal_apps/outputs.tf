output "management_public_ips" {
  description = "Public IPs for management network"
  value       = aws_eip.nsip.*.public_ip
}

output "citrix_adc_instance_ids" {
  description = "Primary and Secondary Citrix ADCs Instance IDs"
  value       = aws_instance.citrix_adc.*.id
}

