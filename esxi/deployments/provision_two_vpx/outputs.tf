output "nsip" {
  description = "NetScaler Management IP addresses"
  value       = var.nsip
}

output "gateway" {
  description = "Network gateway IP"
  value       = var.gw_ip
}

output "subnetmask" {
  description = "Network subnet mask"
  value       = var.subnetmask
}

output "snip" {
  description = "ADC management secondary IP addresses (SNIPs with management access)"
  value       = var.snip
}