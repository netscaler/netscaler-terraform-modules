// aws authentication
aws_access_key   = ""
aws_secret_key   = ""
ssh_pub_key      = "ssh-rsa AAAAB3Nza"
private_key_path = "~/.ssh/id_rsa"

// aws region related inputs
aws_region            = "ap-south-1"
aws_availability_zone = "ap-south-1a"


// Prefix
prefix = "p1"

// VPC related inputs
vpc_cidr_block = "10.0.0.0/16"

management_subnet_cidr_block = "10.0.1.0/24"
client_subnet_cidr_block     = "10.0.2.0/24"
server_subnet_cidr_block     = "10.0.3.0/24"


// CitrixADC (node) related inputs
ns_instance_type = "c4.8xlarge"
ns_tenancy_model = "default" # defalut | dedicated
nodes_password   = "demo123"
key_pair_name    = "demokey"


// Cluster related inputs
cluster_backplane  = "1/1"
cluster_tunnelmode = "GRE"
