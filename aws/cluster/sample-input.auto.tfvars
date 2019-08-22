aws_access_key        = ""
aws_secret_key        = ""
aws_region            = "ap-south-1"
aws_availability_zone = "ap-south-1a"
key_pair_name         = ""

vpc_cidr_block               = "10.0.0.0/16"
ssh_pub_key                  = ""
controlling_subnet           = "0.0.0.0/0"
management_subnet_cidr_block = "10.0.1.0/24"
client_subnet_cidr_block     = "10.0.2.0/24"
server_subnet_cidr_block     = "10.0.3.0/24"

# ADC related inputs
ns_instance_type = "c4.8xlarge"
ns_tenancy_model = "default" # defalut | dedicated

# Cluster related inputs
# Number of initial nodes in the cluster
initial_num_nodes = 3
