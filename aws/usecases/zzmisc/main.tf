variable "aws_region" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}

locals {
  name   = "demotf-vpc"
  region = var.aws_region
}

resource "aws_network_interface" "client" {
  subnet_id         = "subnet-0dae461df8059453e"
  private_ips_count = 2

  tags = {
    Name        = "sumanth-test-network-interface"
    Description = "Client Interface for Citrix ADC"
  }
}

output "nic" {
  value = aws_network_interface.client.private_ip_list[1]
}