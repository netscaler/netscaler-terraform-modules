region       = "us-west1"
zone         = "us-west1-b"
zones        = ["us-west1-b", "us-west1-c"]
project      = "<project>"
machine_type = "n1-standard-8"
image        = "<image>"

management_subnet_cidr_block = "10.0.1.0/24"
client_subnet_cidr_block     = "10.0.2.0/24"
server_subnet_cidr_block     = "10.0.3.0/24"

vip_alias_range             = "10.0.2.6"
citrixadc_rpc_node_password = "Secret@12345"
public_ssh_key_file         = "~/.ssh/id_rsa.pub"
controlling_subnet          = "10.10.10.0/24"
