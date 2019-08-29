# aws authentication
aws_access_key        = ""
aws_secret_key        = ""
ssh_pub_key           = ""


# aws region related inputs
aws_region            = ""
aws_availability_zone = ""


# VPC related inputs
vpc_cidr_block               = "10.0.0.0/16"
management_subnet_cidr_block = "10.0.1.0/24"
client_subnet_cidr_block     = "10.0.2.0/24"
server_subnet_cidr_block     = "10.0.3.0/24"


# CitrixADC (node) related inputs
ns_instance_type = "c4.8xlarge"
ns_tenancy_model = "default" # defalut | dedicated
nodes_password = "nsroot"
key_pair_name         = ""


# Cluster related inputs
initial_num_nodes = 1 # Max is 32
cluster_backplane = "1/1"
cluster_tunnel = "GRE"