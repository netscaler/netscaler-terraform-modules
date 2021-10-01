# Global
region = "europe-west1"
project = "myproject"
zone = "europe-west1-b"
zones = [ "europe-west1-b", "europe-west1-c" ]

# Network
management_subnet_cidr_block = "10.0.1.0/24"
client_subnet_cidr_block = "10.0.2.0/24"
server_subnet_cidr_block = "10.0.3.0/24"

controlling_subnet = "34.140.79.123/32"

public_ssh_key_file = "/home/user/.ssh/id_rsa.pub"

machine_type = "e2-standard-4"
image = "projects/citrix-master-project/global/images/citrix-adc-vpx-byol-13-0-latest"
