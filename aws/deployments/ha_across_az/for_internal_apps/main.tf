# Required Network Infrastructure for Citrix ADC
resource "aws_vpc" "terraform" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "CitrixADC Terraform VPC"
  }
}

resource "aws_subnet" "management" {
  count = 2

  vpc_id                  = aws_vpc.terraform.id
  cidr_block              = var.management_subnet_cidr_list[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.aws_availability_zones[count.index]

  tags = {
    Name = format("Terraform Management Subnet Node %v", count.index)
  }
}

resource "aws_subnet" "client" {
  count = 2

  vpc_id                  = aws_vpc.terraform.id
  cidr_block              = var.client_subnet_cidr_list[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.aws_availability_zones[count.index]

  tags = {
    Name = format("Terraform Public Subnet Node %v", count.index)
  }
}

resource "aws_subnet" "server" {
  count = 2

  vpc_id            = aws_vpc.terraform.id
  cidr_block        = var.server_subnet_cidr_list[count.index]
  availability_zone = var.aws_availability_zones[count.index]

  tags = {
    Name = format("Terraform Server Subnet Node %v", count.index)
  }
}

resource "aws_internet_gateway" "TR_iGW" {
  vpc_id = aws_vpc.terraform.id

  tags = {
    Name = "CitrixADC Terraform Internet Gateway"
  }
}

resource "aws_route_table" "main_rt_table" {
  vpc_id = aws_vpc.terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TR_iGW.id
  }

  tags = {
    Name = "CitrixADC Terraform Main Route Table"
  }
}

resource "aws_main_route_table_association" "TR_main_route" {
  vpc_id         = aws_vpc.terraform.id
  route_table_id = aws_route_table.main_rt_table.id
}


resource "aws_security_group" "management" {
  vpc_id      = aws_vpc.terraform.id
  name        = "Terraform management"
  description = "Allow everything from within the management network and allow limited access to port 22, 80 and 443 from var.citrixadc_management_access_cidr"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.citrixadc_management_access_cidr]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.citrixadc_management_access_cidr]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.citrixadc_management_access_cidr]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = aws_subnet.management.*.cidr_block
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "CitrixADC Terraform Management Security Group"
  }
}

resource "aws_security_group" "client" {
  name        = "Terraform client side"
  description = "Allow Web Traffic from everywhere"

  vpc_id = aws_vpc.terraform.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "CitrixADC Terraform Client Security Group"
  }
}

resource "aws_security_group" "server" {
  name        = "Terraform server side"
  description = "Allow all traffic from the server subnet"

  vpc_id = aws_vpc.terraform.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = aws_subnet.server.*.cidr_block
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "CitrixADC Terraform Server Security Group"
  }
}

# CitrixADC related resources

resource "aws_key_pair" "general_access_key" {
  count = var.new_keypair_required ? 1 : 0

  key_name   = var.aws_ssh_keypair_name
  public_key = file(var.ssh_public_key_filename)
}

data "aws_ami" "latest" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["Citrix ADC ${var.citrixadc_product_version}*${var._citrixadc_aws_product_map[var.citrixadc_product_name]}*"]
  }
}

resource "aws_instance" "citrixadc_primary" {
  tags = {
    Name = "Citrix ADC HA Node PRIMARY"
  }

  ami           = data.aws_ami.latest.id
  instance_type = var.citrixadc_instance_type
  key_name      = var.new_keypair_required ? aws_key_pair.general_access_key[0].key_name : var.aws_ssh_keypair_name

  network_interface {
    network_interface_id = aws_network_interface.management[0].id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.client[0].id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.server[0].id
    device_index         = 2
  }

  availability_zone = var.aws_availability_zones[0]

  iam_instance_profile = aws_iam_instance_profile.citrix_adc_hapip_instance_profile.name

  # Primary CitrixADC configuration
  user_data_base64 = base64encode(<<-EOF
    <NS-PRE-BOOT-CONFIG>
      <NS-CONFIG>
        set systemparameter -promptString "%u@%s"
        set system user nsroot ${var.citrixadc_management_password}
        add ns ip ${aws_network_interface.client[0].private_ip} ${cidrnetmask(var.client_subnet_cidr_list[0])} -type VIP
        add ns ip ${aws_network_interface.server[0].private_ip} ${cidrnetmask(var.server_subnet_cidr_list[0])} -type SNIP

        add ha node 1 ${aws_network_interface.management[1].private_ip} -inc ENABLED
        add lb vserver sample_lb_vserver HTTP ${var.internal_lbvserver_vip} 80

        set ns rpcNode ${aws_network_interface.management[0].private_ip} -password ${var.citrixadc_rpc_node_password} -secure YES
        set ns rpcNode ${aws_network_interface.management[1].private_ip} -password ${var.citrixadc_rpc_node_password} -secure YES

      </NS-CONFIG>
    </NS-PRE-BOOT-CONFIG>
  EOF
  )
}

resource "aws_instance" "citrixadc_secondary" {
  depends_on = [aws_instance.citrixadc_primary]

  tags = {
    Name = "Citrix ADC HA Node SECONDARY"
  }

  ami           = data.aws_ami.latest.id
  instance_type = var.citrixadc_instance_type
  key_name      = var.new_keypair_required ? aws_key_pair.general_access_key[0].key_name : var.aws_ssh_keypair_name

  network_interface {
    network_interface_id = aws_network_interface.management[1].id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.client[1].id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.server[1].id
    device_index         = 2
  }

  availability_zone = var.aws_availability_zones[1]

  iam_instance_profile = aws_iam_instance_profile.citrix_adc_hapip_instance_profile.name

  # Secondary CitrixADC configuration
  user_data_base64 = base64encode(<<-EOF
    <NS-PRE-BOOT-CONFIG>
      <NS-CONFIG>
        set systemparameter -promptString "%u@%s"
        set system user nsroot ${var.citrixadc_management_password}
        add ns ip ${aws_network_interface.client[1].private_ip} ${cidrnetmask(var.client_subnet_cidr_list[1])} -type VIP
        add ns ip ${aws_network_interface.server[1].private_ip} ${cidrnetmask(var.server_subnet_cidr_list[1])} -type SNIP

        add ha node 1 ${aws_network_interface.management[0].private_ip} -inc ENABLED

        set ns rpcNode ${aws_network_interface.management[1].private_ip} -password ${var.citrixadc_rpc_node_password} -secure YES
        set ns rpcNode ${aws_network_interface.management[0].private_ip} -password ${var.citrixadc_rpc_node_password} -secure YES

      </NS-CONFIG>
    </NS-PRE-BOOT-CONFIG>
  EOF
  )
}


resource "aws_iam_role_policy" "citrix_adc_ha_policy" {
  name = "citrix_adc_ha_policy"
  role = aws_iam_role.citrix_adc_hapip_role.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeAddresses",
                "ec2:AssociateAddress",
                "ec2:DisassociateAddress",
                "ec2:DescribeRouteTables",
                "ec2:DeleteRoute",
                "ec2:CreateRoute",
                "ec2:ModifyNetworkInterfaceAttribute",
                "iam:SimulatePrincipalPolicy",
                "iam:GetRole"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role" "citrix_adc_hapip_role" {
  name = "citrix_adc_hapip_role"
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

resource "aws_iam_instance_profile" "citrix_adc_hapip_instance_profile" {
  name = "citrix_adc_hapip_instance_profile"
  path = "/"
  role = aws_iam_role.citrix_adc_hapip_role.name
}

resource "aws_network_interface" "management" {
  count = 2

  subnet_id       = element(aws_subnet.management.*.id, count.index)
  security_groups = [aws_security_group.management.id]

  tags = {
    Name = format("Citrix ADC Management Interface HA Node %v", count.index)
  }
}

resource "aws_network_interface" "client" {
  count = 2

  subnet_id       = element(aws_subnet.client.*.id, count.index)
  security_groups = [aws_security_group.client.id]

  # Assumption: aws_network_interface.client[0] will be assigned to PRIMARY citrix ADC (aws_instance.citrixadc_primary)
  # You must disable Source/Dest Check on the client ENI of the primary instance.
  source_dest_check = count.index == 0 ? false : true

  tags = {
    Name = format("Citrix ADC Client Interface HA Node %v", count.index)
  }
}

resource "aws_network_interface" "server" {
  count = 2

  subnet_id       = element(aws_subnet.server.*.id, count.index)
  security_groups = [aws_security_group.server.id]

  tags = {
    Name = format("Citrix ADC Server Interface HA Node %v", count.index)
  }
}

resource "aws_eip" "nsip" {
  count = 2

  vpc               = true
  network_interface = element(aws_network_interface.management.*.id, count.index)

  # Need to add explicit dependency to avoid binding to ENI when in an invalid state
  depends_on = [aws_instance.citrixadc_primary, aws_instance.citrixadc_secondary]

  tags = {
    Name = format("Citrix ADC NSIP HA Node %v", count.index)
  }
}


# HA for internal apps specific configuration
resource "aws_route" "lbvserver_route" {
  route_table_id         = aws_route_table.main_rt_table.id
  destination_cidr_block = var.internal_lbvserver_vip_cidr_block
  network_interface_id   = aws_network_interface.client.0.id
  depends_on             = [aws_instance.citrixadc_primary, aws_instance.citrixadc_secondary]
}
