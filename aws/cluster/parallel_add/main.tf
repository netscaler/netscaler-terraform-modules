######## AWS related resources
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}


resource "aws_vpc" "terraform" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "Terraform VPC"
  }
}

resource "aws_key_pair" "keypair" {
  key_name   = var.key_pair_name
  public_key = var.ssh_pub_key
}

resource "aws_subnet" "management" {
  vpc_id            = aws_vpc.terraform.id
  cidr_block        = var.management_subnet_cidr_block
  availability_zone = var.aws_availability_zone

  tags = {
    Name = "Terraform Management Subnet"
  }
}

resource "aws_subnet" "client" {
  vpc_id            = aws_vpc.terraform.id
  cidr_block        = var.client_subnet_cidr_block
  availability_zone = var.aws_availability_zone

  tags = {
    Name = "Terraform Public-Client Subnet"
  }
}

resource "aws_subnet" "server" {
  vpc_id            = aws_vpc.terraform.id
  cidr_block        = var.server_subnet_cidr_block
  availability_zone = var.aws_availability_zone

  tags = {
    Name = "Terraform Server Subnet"
  }
}

resource "aws_internet_gateway" "TR_iGW" {
  vpc_id = aws_vpc.terraform.id

  tags = {
    Name = "Terraform Internet Gateway"
  }
}

resource "aws_route_table" "client_rtb" {
  vpc_id = aws_vpc.terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TR_iGW.id
  }

  tags = {
    Name = "Terraform Client-Side Route Table"
  }
}

resource "aws_route_table_association" "client_rtb_association" {
  subnet_id      = aws_subnet.client.id
  route_table_id = aws_route_table.client_rtb.id
}

#resource "aws_main_route_table_association" "client_rtb_association" {
#  vpc_id         = aws_vpc.terraform.id
#  route_table_id = aws_route_table.client_rtb.id
#}

resource "aws_eip" "nat_gw" {
  vpc = true

  tags = {
    Name = "NAT_GW EIP"
  }
}
resource "aws_nat_gateway" "management_nat_gw" {
  allocation_id = aws_eip.nat_gw.id
  subnet_id     = aws_subnet.client.id

  depends_on = ["aws_internet_gateway.TR_iGW"]
  tags = {
    Name = "Management NAT_GW"
  }
}

resource "aws_route_table" "management_rtb" {
  vpc_id = aws_vpc.terraform.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.management_nat_gw.id
  }

  tags = {
    Name = "Terraform Management Route Table"
  }
}

resource "aws_route_table_association" "mgmt_rtb_association" {
  subnet_id      = aws_subnet.management.id
  route_table_id = aws_route_table.management_rtb.id
}

#resource "aws_main_route_table_association" "management_rtb_association" {
#  vpc_id         = aws_vpc.terraform.id
#  route_table_id = aws_route_table.management_rtb.id
#}

resource "aws_security_group" "inside_allow_all" {
  vpc_id      = aws_vpc.terraform.id
  name        = "inside_allow_all"
  description = "Allow everything from within the network"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "inside_allow_all"
  }
}

resource "aws_security_group" "outside_world" {
  vpc_id      = aws_vpc.terraform.id
  name        = "outside_world"
  description = "outside world traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "outside_world"
  }
}

resource "aws_instance" "test_ubuntu" {
  ami           = var.ubuntu_ami_map[var.aws_region]
  instance_type = "t2.micro"
  key_name      = var.key_pair_name

  network_interface {
    network_interface_id = aws_network_interface.ubuntu_client.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.ubuntu_management.id
    device_index         = 1
  }

  tags = {
    Name = "test_ubuntu"
  }

}

resource "null_resource" "add_nodes_serially" {
  count = (tonumber(var.initial_num_nodes) <= tonumber(var.cco_id)) ? 0 : 1
  triggers = {
    build_number = "${timestamp()}"
  }
  

  depends_on = [null_resource.ubuntu_file_provisioner, aws_instance.citrix_adc, aws_network_interface.management]
}

resource "null_resource" "ubuntu_file_provisioner" {
  triggers = {
    build_number = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = tonumber(var.initial_num_nodes) == 0 ? "true" : "sleep 40 && scp -o StrictHostKeyChecking=no -i ${var.private_key_path} cluster.py ubuntu@${aws_eip.test_ubuntu.public_ip}:/home/ubuntu/cluster.py"
  }

  # lifecycle {
  #   prevent_destroy = true
  # }

  depends_on = [aws_instance.test_ubuntu]
}

resource "null_resource" "save_clip_config" {
  triggers = {
    build_number = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = tonumber(var.initial_num_nodes) == 0 ? "true" : "sleep 15 && ssh -i ${var.private_key_path} ubuntu@${aws_eip.test_ubuntu.public_ip} 'python3 cluster.py --save-config --all-ips ${join(" ",
    aws_network_interface.management[*].private_ip)} --nspass ${var.nodes_password} '"
  }
  depends_on = [aws_instance.citrix_adc, null_resource.add_nodes_serially]
}

resource "aws_network_interface" "ubuntu_client" {
  subnet_id       = aws_subnet.client.id
  security_groups = [aws_security_group.outside_world.id]

  tags = {
    Name        = "Ubuntu Public-Client ENI"
    Description = "Ubuntu Public-Client ENI"
  }
}

resource "aws_eip" "test_ubuntu" {
  vpc               = true
  network_interface = aws_network_interface.ubuntu_client.id

  # Need to add explicit dependency to avoid binding to ENI when in an invalid state
  depends_on = [aws_instance.test_ubuntu]

  tags = {
    Name = "Ubuntu Public-Client EIP"
  }
}

resource "aws_network_interface" "ubuntu_management" {
  subnet_id       = aws_subnet.management.id
  security_groups = [aws_security_group.inside_allow_all.id]

  tags = {
    Name        = "Ubuntu Management ENI"
    Description = "Ubuntu Management ENI"
  }
}


# Citrix related resources
resource "aws_instance" "citrix_adc" {
  count         = var.initial_num_nodes
  ami           = var.vpx_ami_map[var.aws_region]
  instance_type = var.ns_instance_type
  key_name      = var.key_pair_name
  tenancy       = var.ns_tenancy_model

  network_interface {
    network_interface_id = element(aws_network_interface.management.*.id, count.index)
    device_index         = 0
  }

  network_interface {
    network_interface_id = element(aws_network_interface.client.*.id, count.index)
    device_index         = 1
  }

  network_interface {
    network_interface_id = element(aws_network_interface.server.*.id, count.index)
    device_index         = 2
  }
  provisioner "local-exec" {
    command =  "sleep  ${count.index == 0 ? 60 : 360  } && ssh -i ${var.private_key_path} ubuntu@${aws_eip.test_ubuntu.public_ip} 'python3 cluster.py --clip ${
      element(tolist(aws_network_interface.management[tonumber(var.cco_id)].private_ips), 0)
      == aws_network_interface.management[tonumber(var.cco_id)].private_ip
      ? element(tolist(aws_network_interface.management[tonumber(var.cco_id)].private_ips), 1) :
      element(tolist(aws_network_interface.management[tonumber(var.cco_id)].private_ips), 0)} --node-ips ${self.private_ip} --node-ids ${count.index} --inst-ids ${self.id} --backplane ${var.cluster_backplane} --tunnelmode ${
      var.cluster_tunnelmode}  --nspass ${var.nodes_password}'"
    
  }
  depends_on = [null_resource.ubuntu_file_provisioner, aws_instance.test_ubuntu, aws_eip.test_ubuntu]

  iam_instance_profile = aws_iam_instance_profile.citrix_adc_cluster_instance_profile_1.name

  tags = {
    Name = format("CitrixADC Node %v", count.index)
  }

  provisioner "local-exec" {
    when = "destroy"
    command = (tonumber(var.initial_num_nodes) == 0) ? "true" : "sleep ${60 * (count.index - tonumber(var.initial_num_nodes))} && ssh -i ${var.private_key_path} ubuntu@${aws_eip.test_ubuntu.public_ip} 'python3 cluster.py --delete --clip ${
      element(tolist(aws_network_interface.management[tonumber(var.cco_id)].private_ips), 0)
      == aws_network_interface.management[tonumber(var.cco_id)].private_ip
      ? element(tolist(aws_network_interface.management[tonumber(var.cco_id)].private_ips), 1) :
      element(tolist(aws_network_interface.management[tonumber(var.cco_id)].private_ips), 0)} --node-ips ${self.private_ip} --nspass ${var.nodes_password} --all-ips ${join(" ",
    aws_network_interface.management[*].private_ip)}'"
  }

  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_iam_role_policy" "citrix_adc_cluster_policy_1" {
  name = "citrix_adc_cluster_policy_1"
  role = aws_iam_role.citrix_adc_cluster_role_1.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeAddresses",
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
        "ec2:DescribeInstances",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DetachNetworkInterface",
        "ec2:AttachNetworkInterface",
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:RebootInstances",
        "ec2:AssignPrivateIpAddresses",
        "autoscaling:*",
        "sns:*",
        "sqs:*",
        "iam:GetRole",
        "iam:SimulatePrincipalPolicy",
        "cloudwatch:*"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role" "citrix_adc_cluster_role_1" {
  name = "citrix_adc_cluster_role_1"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      }
    }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "citrix_adc_cluster_instance_profile_1" {
  name = "citrix_adc_cluster_instance_profile_1"
  path = "/"
  role = aws_iam_role.citrix_adc_cluster_role_1.name
}


resource "aws_network_interface" "management" {
  count             = var.initial_num_nodes
  subnet_id         = aws_subnet.management.id
  security_groups   = [aws_security_group.inside_allow_all.id]
  private_ips_count = count.index == tonumber(var.cco_id) ? 1 : 0 # Create secondary IPs only for the cluster node. This secondary IP acts as Cluster IP

  tags = {
    Name        = format("Terraform NS Management interface %v", count.index)
    Description = format("Management Interface for Citrix ADC %v", count.index)
  }
}

resource "aws_network_interface" "client" {
  count           = var.initial_num_nodes
  subnet_id       = aws_subnet.client.id
  security_groups = [aws_security_group.inside_allow_all.id]

  tags = {
    Name        = format("Terraform NS Public-Client Interface %v", count.index)
    Description = format("Public-Client Interface for Citrix ADC %v", count.index)
  }
}

resource "aws_network_interface" "server" {
  count           = var.initial_num_nodes
  subnet_id       = aws_subnet.server.id
  security_groups = [aws_security_group.inside_allow_all.id]

  tags = {
    Name        = format("Terraform NS Server Interface %v", count.index)
    Description = format("Server Interface for Citrix ADC %v", count.index)
  }
}

