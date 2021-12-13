aws_region     = "us-east-1"
aws_access_key = "ADXXXXXXAEDEFEA"
aws_secret_key = "asdreDAFaeasdXXXXXXXXXXXaaealsdkfalsdk"

vpc_cidr_block         = "10.0.0.0/16"
aws_availability_zones = ["us-east-1a", "us-east-1b"]

management_subnet_cidr_blocks     = ["10.0.1.0/24", "10.0.4.0/24"]
client_subnet_cidr_blocks         = ["10.0.2.0/24", "10.0.5.0/24"]
server_subnet_cidr_blocks         = ["10.0.3.0/24", "10.0.6.0/24"]
restricted_mgmt_access_cidr_block = "x.x.x.x/x"

aws_ssh_key_name   = "key-pair-name"
aws_ssh_public_key = "ssh-rsa AAAAB3"

internal_lbvserver_vip_cidr_block = "192.168.0.0/16"
internal_lbvserver_vip            = "192.168.2.2"

