######## AWS related resources related resources #########

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_vpc" "terraform" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = format("%v-Terraform VPC", var.prefix)
  }
}

resource "aws_key_pair" "keypair" {
  key_name   = format("%v-%v", var.prefix, var.key_pair_name)
  public_key = var.ssh_pub_key
}

resource "aws_subnet" "management" {
  vpc_id            = aws_vpc.terraform.id
  cidr_block        = var.management_subnet_cidr_block
  availability_zone = var.aws_availability_zone

  tags = {
    Name = format("%v-Terraform Management Subnet", var.prefix)
  }
}

resource "aws_subnet" "client" {
  vpc_id            = aws_vpc.terraform.id
  cidr_block        = var.client_subnet_cidr_block
  availability_zone = var.aws_availability_zone

  tags = {
    Name = format("%v-Terraform Public-Client Subnet", var.prefix)
  }
}

resource "aws_subnet" "server" {
  vpc_id            = aws_vpc.terraform.id
  cidr_block        = var.server_subnet_cidr_block
  availability_zone = var.aws_availability_zone

  tags = {
    Name = format("%v-Terraform Server Subnet", var.prefix)
  }
}

resource "aws_internet_gateway" "TR_iGW" {
  vpc_id = aws_vpc.terraform.id

  tags = {
    Name = format("%v-Terraform Internet Gateway", var.prefix)
  }
}

resource "aws_route_table" "client_rtb" {
  vpc_id = aws_vpc.terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TR_iGW.id
  }

  tags = {
    Name = format("%v-Terraform Client-Side Route Table", var.prefix)
  }
}

resource "aws_route_table_association" "client_rtb_association" {
  subnet_id      = aws_subnet.client.id
  route_table_id = aws_route_table.client_rtb.id
}

resource "aws_eip" "nat_gw" {
  vpc = true

  tags = {
    Name = format("%v-NAT_GW EIP", var.prefix)
  }
}

resource "aws_nat_gateway" "management_nat_gw" {
  allocation_id = aws_eip.nat_gw.id
  subnet_id     = aws_subnet.client.id

  depends_on = ["aws_internet_gateway.TR_iGW"]
  tags = {
    Name = format("%v-Management NAT_GW", var.prefix)
  }
}

resource "aws_route_table" "management_rtb" {
  vpc_id = aws_vpc.terraform.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.management_nat_gw.id
  }

  tags = {
    Name = format("%v-Terraform Management Route Table", var.prefix)
  }
}

resource "aws_route_table_association" "mgmt_rtb_association" {
  subnet_id      = aws_subnet.management.id
  route_table_id = aws_route_table.management_rtb.id
}

resource "aws_security_group" "inside_allow_all" {
  vpc_id      = aws_vpc.terraform.id
  name        = format("%v-inside_allow_all", var.prefix)
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
    Name = format("%v-inside_allow_all", var.prefix)
  }
}

resource "aws_security_group" "outside_world" {
  vpc_id      = aws_vpc.terraform.id
  name        = format("%v-outside_world", var.prefix)
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
    Name = format("%v-outside_world", var.prefix)
  }
}

########## Ubuntu JumpBox related resources ########
resource "aws_instance" "test_ubuntu" {
  ami           = var.ubuntu_ami_map[var.aws_region]
  instance_type = "t2.micro"
  key_name      = format("%v-%v", var.prefix, var.key_pair_name)

  network_interface {
    network_interface_id = aws_network_interface.ubuntu_client.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.ubuntu_management.id
    device_index         = 1
  }

  tags = {
    Name = format("%v-test_ubuntu", var.prefix)
  }
}

resource "aws_network_interface" "ubuntu_client" {
  subnet_id       = aws_subnet.client.id
  security_groups = [aws_security_group.outside_world.id]

  tags = {
    Name        = format("%v-Ubuntu Public-Client ENI", var.prefix)
    Description = "Ubuntu Public-Client ENI"
  }
}

resource "aws_eip" "test_ubuntu" {
  vpc               = true
  network_interface = aws_network_interface.ubuntu_client.id

  # Need to add explicit dependency to avoid binding to ENI when in an invalid state
  depends_on = [aws_instance.test_ubuntu]

  tags = {
    Name = format("%v-Ubuntu Public-Client EIP", var.prefix)
  }
}

resource "aws_network_interface" "ubuntu_management" {
  subnet_id       = aws_subnet.management.id
  security_groups = [aws_security_group.inside_allow_all.id]

  tags = {
    Name        = format("%v-Ubuntu Management ENI", var.prefix)
    Description = "Ubuntu Management ENI"
  }
}

##### CitrixADC (cluster node) related resources
resource "aws_instance" "citrix_adc" {
  count         = var.initial_num_nodes
  ami           = var.vpx_ami_map[var.aws_region]
  instance_type = var.ns_instance_type
  key_name      = format("%v-%v", var.prefix, var.key_pair_name)
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

  depends_on = [null_resource.ubuntu_file_provisioner, aws_instance.test_ubuntu, aws_eip.test_ubuntu]

  iam_instance_profile = aws_iam_instance_profile.citrix_adc_cluster_instance_profile.name

  tags = {
    Name = format("%v-CitrixADC Node %v", var.prefix, count.index)
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

resource "aws_iam_role_policy" "citrix_adc_cluster_policy" {
  name = format("%v-citrix_adc_cluster_policy", var.prefix)
  role = aws_iam_role.citrix_adc_cluster_role.name

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

resource "aws_iam_role" "citrix_adc_cluster_role" {
  name = format("%v-citrix_adc_cluster_role", var.prefix)
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

resource "aws_iam_instance_profile" "citrix_adc_cluster_instance_profile" {
  name = format("%v-citrix_adc_cluster_instance_profile", var.prefix)
  path = "/"
  role = aws_iam_role.citrix_adc_cluster_role.name
}

resource "aws_network_interface" "management" {
  count             = var.initial_num_nodes
  subnet_id         = aws_subnet.management.id
  security_groups   = [aws_security_group.inside_allow_all.id]
  private_ips_count = count.index == tonumber(var.cco_id) ? 1 : 0 # Create secondary IPs only for the cluster node. This secondary IP acts as Cluster IP

  tags = {
    Name        = format("%v-Terraform NS Management interface %v", var.prefix, count.index)
    Description = format("Management Interface for Citrix ADC %v", count.index)
  }
}

resource "aws_network_interface" "client" {
  count           = var.initial_num_nodes
  subnet_id       = aws_subnet.client.id
  security_groups = [aws_security_group.inside_allow_all.id]

  tags = {
    Name        = format("%v-Terraform NS Public-Client Interface %v", var.prefix, count.index)
    Description = format("Public-Client Interface for Citrix ADC %v", count.index)
  }
}

resource "aws_network_interface" "server" {
  count           = var.initial_num_nodes
  subnet_id       = aws_subnet.server.id
  security_groups = [aws_security_group.inside_allow_all.id]

  tags = {
    Name        = format("%v-Terraform NS Server Interface %v", var.prefix, count.index)
    Description = format("Server Interface for Citrix ADC %v", count.index)
  }
}

######### Null Resources #####
resource "null_resource" "add_nodes_serially" {
  count = (tonumber(var.initial_num_nodes) <= tonumber(var.cco_id)) ? 0 : 1
  triggers = {
    build_number = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = tonumber(var.initial_num_nodes) == 0 ? "true" : "sleep  60  && ssh -i ${var.private_key_path} ubuntu@${aws_eip.test_ubuntu.public_ip} 'python3 cluster.py --clip ${
      element(tolist(aws_network_interface.management[tonumber(var.cco_id)].private_ips), 0)
      == aws_network_interface.management[tonumber(var.cco_id)].private_ip
      ? element(tolist(aws_network_interface.management[tonumber(var.cco_id)].private_ips), 1) :
      element(tolist(aws_network_interface.management[tonumber(var.cco_id)].private_ips), 0)} --node-ips ${join(" ",
        aws_network_interface.management[*].private_ip)} --node-ids ${join(" ",
        range(var.initial_num_nodes))} --inst-ids ${join(" ",
      aws_instance.citrix_adc[*].id)} --backplane ${var.cluster_backplane} --tunnelmode ${
      var.cluster_tunnelmode}  --nspass ${var.nodes_password} --all-ips ${join(" ",
    aws_network_interface.management[*].private_ip)}'"
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

