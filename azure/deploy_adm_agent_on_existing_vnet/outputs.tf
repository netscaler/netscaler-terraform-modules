output "public_ip" {
  value = azurerm_public_ip.terraform-agent-public-ip.ip_address
}