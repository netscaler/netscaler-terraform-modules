# VPC Infrastructure

resource "aws_vpc" "terraform" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "CitrixADC Terraform VPC"
  }
}

resource "aws_subnet" "management" {
  vpc_id                  = aws_vpc.terraform.id
  cidr_block              = var.management_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.aws_availability_zone

  tags = {
    Name = "CitrixADC Terraform Management Subnet"
  }
}

resource "aws_subnet" "client" {
  vpc_id                  = aws_vpc.terraform.id
  cidr_block              = var.client_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.aws_availability_zone

  tags = {
    Name = "CitrixADC Terraform Public Subnet"
  }
}

resource "aws_subnet" "server" {
  vpc_id            = aws_vpc.terraform.id
  cidr_block        = var.server_subnet_cidr
  availability_zone = var.aws_availability_zone

  tags = {
    Name = "CitrixADC Terraform Server Subnet"
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
    cidr_blocks = [aws_subnet.management.cidr_block]
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
    cidr_blocks = [aws_subnet.server.cidr_block]
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

resource "aws_instance" "citrix_adc" {
  count = 2

  tags = {
    Name = format("Citrix ADC VPX %v", count.index)
  }


  ami           = data.aws_ami.latest.id
  instance_type = var.citrixadc_instance_type
  key_name      = var.new_keypair_required ? aws_key_pair.general_access_key[0].key_name : var.aws_ssh_keypair_name

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

  availability_zone = var.aws_availability_zone

  iam_instance_profile = aws_iam_instance_profile.citrix_adc_ha_instance_profile.name

  user_data_base64 = base64encode(<<-EOF
    <NS-PRE-BOOT-CONFIG>
      <NS-CONFIG>
        set systemparameter -promptString "%u@%s"
        set system user nsroot ${var.citrixadc_management_password}
        add ns ip ${element(aws_network_interface.client.*.private_ip, count.index)} ${cidrnetmask(var.client_subnet_cidr)} -type VIP
        add ns ip ${element(aws_network_interface.server.*.private_ip, count.index)} ${cidrnetmask(var.server_subnet_cidr)} -type SNIP

        add ha node 1 ${element(aws_network_interface.management.*.private_ip, count.index == 0 ? 1 : 0)}

        set ns rpcNode ${element(aws_network_interface.management.*.private_ip, count.index)} -password ${var.citrixadc_rpc_node_password} -secure YES
        set ns rpcNode ${element(aws_network_interface.management.*.private_ip, count.index == 0 ? 1 : 0)} -password ${var.citrixadc_rpc_node_password} -secure YES

      </NS-CONFIG>
    </NS-PRE-BOOT-CONFIG>
  EOF
  )
}


resource "aws_iam_role_policy" "citrix_adc_ha_policy" {
  name = "citrix_adc_ha_policy"
  role = aws_iam_role.citrix_adc_ha_role.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DetachNetworkInterface",
        "ec2:AttachNetworkInterface",
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:RebootInstances",
        "autoscaling:*",
        "sns:*",
        "iam:SimulatePrincipalPolicy",
        "iam:GetRole",
        "sqs:*"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role" "citrix_adc_ha_role" {
  name = "citrix_adc_ha_role"
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

resource "aws_iam_instance_profile" "citrix_adc_ha_instance_profile" {
  name = "citrix_adc_ha_instance_profile"
  path = "/"
  role = aws_iam_role.citrix_adc_ha_role.name
}

resource "aws_network_interface" "management" {
  count = 2

  subnet_id       = aws_subnet.management.id
  security_groups = [aws_security_group.management.id]

  tags = {
    Name = format("Citrix ADC Management Interface HA Node %v", count.index)
  }

}

resource "aws_network_interface" "client" {
  count = 2

  subnet_id       = aws_subnet.client.id
  security_groups = [aws_security_group.client.id]

  tags = {
    Name = format("Citrix ADC Client Interface HA Node %v", count.index)
  }
}

resource "aws_network_interface" "server" {
  count = 2

  subnet_id       = aws_subnet.server.id
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
  depends_on = [aws_instance.citrix_adc]

  tags = {
    Name = format("Citrix ADC NSIP HA Node %v", count.index)
  }
}

resource "aws_eip" "client" {
  vpc               = true
  network_interface = aws_network_interface.client[0].id

  # Need to add explicit dependency to avoid binding to ENI when in an invalid state
  depends_on = [aws_instance.citrix_adc]

  tags = {
    Name = "CitrixADC Terraform Public Data IP"
  }
}
