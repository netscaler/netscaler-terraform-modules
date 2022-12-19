aws_region = "ap-southeast-1"

vpc_cidr                    = "10.0.0.0/16"
management_subnet_cidr_list = ["10.0.1.0/24", "10.0.4.0/24"]
client_subnet_cidr_list     = ["10.0.2.0/24", "10.0.5.0/24"]
server_subnet_cidr_list     = ["10.0.3.0/24", "10.0.6.0/24"]
server_subnet_masks         = ["255.255.255.0", "255.255.255.0"]

aws_availability_zones           = ["ap-southeast-1a", "ap-southeast-1b"]
new_keypair_required             = true
aws_ssh_keypair_name             = "test-keypair-ap-southeast-1" # If the above `new_keypair_required` is `false`, then this keypair name should be existing in the `aws_region`
ssh_public_key_filename          = "~/.ssh/test.pub"
citrixadc_management_access_cidr = "11.11.0.0/16"
citrixadc_management_password    = "verystrongpassword"
citrixadc_rpc_node_password      = "newrpcnodepassword"
citrixadc_instance_type          = "m5.xlarge"
citrixadc_product_name           = "Citrix ADC VPX - Customer Licensed"
citrixadc_product_version        = "13.1"

internal_lbvserver_vip_cidr_block = "192.168.0.0/16"
internal_lbvserver_vip            = "192.168.2.2"
