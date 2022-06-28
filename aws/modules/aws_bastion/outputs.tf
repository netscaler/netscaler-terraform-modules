output "bastion_host_public_ip" {
  value       = aws_instance.this.public_ip
  description = "Public IP of the Bastion Host"
}
