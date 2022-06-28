output "citrixadc_management_public_ip" {
  description = "CitrixADC Management Public IP"
  value       = var.is_mgmt_public_ip_required ? aws_eip.mgmt[0].public_ip : null
}

output "citrixadc_management_private_ip" {
  description = "CitrixADC Management Private IP"
  value       = aws_network_interface.management.private_ip
}

output "citrixadc_client_public_ip" {
  description = "CitrixADC Client Public IP"
  value       = var.is_client_public_ip_required ? aws_eip.client[0].public_ip : null
}

output "citrixadc_client_private_ip" {
  description = "CitrixADC Client Private IP"
  value       = aws_network_interface.client.private_ip
}

output "citrixadc_instance_id" {
  description = "CitrixADC Instance ID"
  value       = aws_instance.citrix_adc.id
}

output "citrixadc_client_network_interface" {
  description = "CitrixADC Client Network Interface"
  value       = aws_network_interface.client
}
