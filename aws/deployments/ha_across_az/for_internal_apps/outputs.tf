output "citrixadc_management_public_ips" {
  description = "List of the public IP addresses assigned to Primary and Secondary CitrixADC management interfaces."
  value       = aws_eip.nsip.*.public_ip
}

output "citrixadc_instance_ids" {
  description = "List of the CitrixADC VPX instances ids."
  value       = [aws_instance.citrixadc_primary.id, aws_instance.citrixadc_secondary.id]
}

