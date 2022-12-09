aws_region = "ap-southeast-1"

vpc_cidr               = "10.0.0.0/16"
management_subnet_cidr = "10.0.1.0/24"
client_subnet_cidr     = "10.0.2.0/24"
server_subnet_cidr     = "10.0.3.0/24"

aws_availability_zone            = "ap-southeast-1a"
new_keypair_required             = true
aws_ssh_keypair_name             = "test-keypair-ap-southeast-1" # If the above `new_keypair_required` is `false`, then this keypair name should be existing in the `aws_region`
ssh_public_key_filename          = "~/.ssh/test.pub"
citrixadc_management_access_cidr = "15.10.0.0/16"
citrixadc_management_password    = "verystrongpassword"
citrixadc_rpc_node_password      = "newrpcnodepassword"
citrixadc_instance_type          = "m5.xlarge"
citrixadc_product_version        = "13.1"
citrixadc_product_name           = "Citrix ADC VPX - Customer Licensed"
