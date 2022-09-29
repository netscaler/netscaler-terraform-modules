# Network Related
resource "aws_vpc" "terraform" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "Terraform VPC"
  }
}

resource "aws_subnet" "management" {
  vpc_id                  = aws_vpc.terraform.id
  cidr_block              = var.management_subnet_cidr_blocks[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.aws_availability_zones[count.index]

  tags = {
    Name = format("Terraform Management Subnet Node %v", count.index)
  }

  count = 2
}

resource "aws_subnet" "client" {
  vpc_id                  = aws_vpc.terraform.id
  cidr_block              = var.client_subnet_cidr_blocks[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.aws_availability_zones[count.index]

  tags = {
    Name = format("Terraform Public Subnet Node %v", count.index)
  }

  count = 2
}

resource "aws_subnet" "server" {
  vpc_id            = aws_vpc.terraform.id
  cidr_block        = var.server_subnet_cidr_blocks[count.index]
  availability_zone = var.aws_availability_zones[count.index]

  tags = {
    Name = format("Terraform Server Subnet Node %v", count.index)
  }

  count = 2
}

resource "aws_internet_gateway" "TR_iGW" {
  vpc_id = aws_vpc.terraform.id

  tags = {
    Name = "Terraform Internet Gateway"
  }
}

resource "aws_route_table" "main_rt_table" {
  vpc_id = aws_vpc.terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TR_iGW.id
  }

  tags = {
    Name = "Terraform Main Route Table"
  }
}

resource "aws_route" "lbvserver_route" {
  route_table_id         = aws_route_table.main_rt_table.id
  destination_cidr_block = var.internal_lbvserver_vip_cidr_block
  network_interface_id   = aws_network_interface.client.0.id
  depends_on = [aws_instance.citrix_adc]
}

resource "aws_main_route_table_association" "TR_main_route" {
  vpc_id         = aws_vpc.terraform.id
  route_table_id = aws_route_table.main_rt_table.id
}


resource "aws_security_group" "management" {
  vpc_id      = aws_vpc.terraform.id
  name        = "Terraform management"
  description = "Allow everything from within the management network and the controlling node."

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = concat([var.restricted_mgmt_access_cidr_block], aws_subnet.management.*.cidr_block)
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = concat([var.restricted_mgmt_access_cidr_block], aws_subnet.management.*.cidr_block)
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = concat([var.restricted_mgmt_access_cidr_block], aws_subnet.management.*.cidr_block)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Terraform Management Security Group"
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
    Name = "Terraform Client Security Group"
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
    Name = "Terraform Server Security Group"
  }
}

# Key
resource "aws_key_pair" "general_access_key" {
  key_name   = var.aws_ssh_key_name
  public_key = var.aws_ssh_public_key
}

# Citrix ADC related
resource "aws_instance" "citrix_adc" {
  ami           = var.vpx_ami_map[var.aws_region]
  instance_type = var.ns_instance_type
  key_name      = var.aws_ssh_key_name

  network_interface {
    network_interface_id = element(aws_network_interface.management.*.id, count.index)
    device_index         = 0
  }

  availability_zone = var.aws_availability_zones[count.index]

  iam_instance_profile = aws_iam_instance_profile.citrix_adc_hapip_instance_profile.name

  tags = {
    Name = format("Citrix ADC HA Node %v", count.index)
  }

  user_data_base64 = base64encode(<<EOF
                <NS-PRE-BOOT-CONFIG>
                    <NS-CONFIG>
                        set systemparameter -promptString "%u@%s"
                        add ha node 1 ${element(aws_network_interface.management.*.private_ip, count.index == 0 ? 1 : 0)} -inc ENABLED
                        ${count.index == 0 ? local.add_lbvserver_cli : ""}
                    </NS-CONFIG>
                </NS-PRE-BOOT-CONFIG>
  EOF
  )
  count = 2
}
locals {
  add_lbvserver_cli = "add lb vserver sample_lb_vserver HTTP ${var.internal_lbvserver_vip} 80"
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
  subnet_id       = element(aws_subnet.management.*.id, count.index)
  security_groups = [aws_security_group.management.id]

  tags = {
    Name = format("Citrix ADC Management Interface HA Node %v", count.index)
  }

  count = 2
}

resource "aws_network_interface" "client" {
  subnet_id       = element(aws_subnet.client.*.id, count.index)
  security_groups = [aws_security_group.client.id]

  # if count.index is 0 then source_dest_check is false else true
  source_dest_check = count.index == 0 ? false : true

  attachment {
    instance     = element(aws_instance.citrix_adc.*.id, count.index)
    device_index = 1
  }

  tags = {
    Name = format("Citrix ADC Client Interface HA Node %v", count.index)
  }

  count = 2
}

resource "aws_network_interface" "server" {
  subnet_id       = element(aws_subnet.server.*.id, count.index)
  security_groups = [aws_security_group.server.id]

  attachment {
    instance     = element(aws_instance.citrix_adc.*.id, count.index)
    device_index = 2
  }

  tags = {
    Name = format("Citrix ADC Server Interface HA Node %v", count.index)
  }

  count = 2
}

resource "aws_eip" "nsip" {
  vpc               = true
  network_interface = element(aws_network_interface.management.*.id, count.index)

  # Need to add explicit dependency to avoid binding to ENI when in an invalid state
  depends_on = [aws_instance.citrix_adc]

  tags = {
    Name = format("Citrix ADC NSIP HA Node %v", count.index)
  }

  count = 2
}

