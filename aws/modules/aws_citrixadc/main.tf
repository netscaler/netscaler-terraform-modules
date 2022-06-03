resource "aws_key_pair" "deployer" {
  count      = var.is_new_keypair_required ? 1 : 0
  key_name   = var.keypair_name
  public_key = file(var.keypair_filepath)
}

resource "aws_security_group" "management" {
  vpc_id      = var.vpc_id
  name        = "${var.deploy_prefix}-ManagementSG"
  description = "Allow everything from within the management network and SSH, HTTP, HTTPS access restricted access"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.restricted_mgmt_access_cidr]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.restricted_mgmt_access_cidr]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.restricted_mgmt_access_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.deploy_prefix}-Management Security Group"
  }
}

resource "aws_security_group" "client" {
  name        = "${var.deploy_prefix}-ClientSG"
  description = "Allow Client Traffic from everywhere"

  vpc_id = var.vpc_id

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
    Name = "${var.deploy_prefix}-Client Security Group"
  }
}

resource "aws_security_group" "server" {
  name        = "${var.deploy_prefix}-server side"
  description = "Allow all traffic from the server subnet"

  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.deploy_prefix}-Server Security Group"
  }
}


####### Citrix ADC Provisioning ########
data "aws_ami" "latest" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["Citrix ADC ${var.citrixadc_product_version}*${var._citrixadc_aws_product_map[var.citrixadc_product_name]}*"]
  }
}
resource "aws_instance" "citrix_adc" {
  ami           = var.citrixadc_userami == "" ? data.aws_ami.latest.id : var.citrixadc_userami
  instance_type = var.citrixadc_instance_type
  key_name      = var.is_new_keypair_required ? aws_key_pair.deployer[0].key_name : var.keypair_name

  iam_instance_profile = var.iam_instance_profile_name == "" ? null : var.iam_instance_profile_name

  network_interface {
    network_interface_id = aws_network_interface.management.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.client.id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.server.id
    device_index         = 2
  }

  tags = {
    Name = "${var.deploy_prefix}-CitrixADC-${var.citrixadc_product_version}-${var.citrixadc_product_name}"
  }

  # user_data_base64 = base64encode(<<EOF
  #   <NS-PRE-BOOT-CONFIG>
  #       <NS-CONFIG>
  #           set systemparameter -promptString "%u@%s"
  #           set system user nsroot ${var.citrixadc_admin_password}
  #           add ns ip ${aws_network_interface.client.private_ip} -type VIP
  #           add ns ip ${aws_network_interface.server.private_ip} -type SNIP
  #       </NS-CONFIG>
  #   </NS-PRE-BOOT-CONFIG>
  # EOF
  # )

  user_data_base64 = base64encode(<<-EOF
    <NS-PRE-BOOT-CONFIG>
      %{if var.is_allocate_license}
        <NS-LICENSE-CONFIG>
          <LICENSE-COMMANDS>
              add ns licenseserver ${var.license_server_ip} -port 27000
              set ns capacity -unit Mbps -bandwidth ${var.pooled_license_bandwidth} edition ${var.pooled_license_edition}
          </LICENSE-COMMANDS>
        </NS-LICENSE-CONFIG>
      %{endif}
      <NS-CONFIG>
        set systemparameter -promptString "%u@%s"
        set system user nsroot ${var.citrixadc_admin_password}
        add ns ip ${aws_network_interface.client.private_ip} ${cidrnetmask(var.client_subnet_cidr)} -type VIP
        add ns ip ${aws_network_interface.server.private_ip} ${cidrnetmask(var.server_subnet_cidr)} -type SNIP
        %{if var.citrixadc_firstboot_commands != ""}
          ${var.citrixadc_firstboot_commands}
        %{endif}
      </NS-CONFIG>
    </NS-PRE-BOOT-CONFIG>
  EOF
  )
}

resource "aws_network_interface" "management" {
  subnet_id       = var.management_subnet_id
  security_groups = [aws_security_group.management.id]

  tags = {
    Name        = "${var.deploy_prefix}-CitrixADC Management interface"
    Description = "MGMT Interface for Citrix ADC"
  }
}

resource "aws_network_interface" "client" {
  subnet_id         = var.client_subnet_id
  security_groups   = [aws_security_group.client.id]
  private_ips_count = var.client_network_interface_secondary_private_ips_count
  source_dest_check = var.enable_client_eni_source_dest_check

  # attachment {
  #   instance     = aws_instance.citrix_adc.id
  #   device_index = 1
  # }

  tags = {
    Name        = "${var.deploy_prefix}-CitrixADC Client Interface"
    Description = "Client Interface for Citrix ADC"
  }
}

resource "aws_network_interface" "server" {
  subnet_id       = var.server_subnet_id
  security_groups = [aws_security_group.server.id]

  # attachment {
  #   instance     = aws_instance.citrix_adc.id
  #   device_index = 2
  # }

  tags = {
    Name        = "${var.deploy_prefix}-CitrixADC Server Interface"
    Description = "Server Interface for Citrix ADC"
  }
}

resource "aws_eip" "mgmt" {
  # run this resource only when var.is_mgmt_public_ip_required is true
  count = var.is_mgmt_public_ip_required ? 1 : 0

  vpc               = true
  network_interface = aws_network_interface.management.id

  # Need to add explicit dependency to avoid binding to ENI when in an invalid state
  depends_on = [aws_instance.citrix_adc]

  tags = {
    Name = "${var.deploy_prefix}-Management Public NSIP"
  }
}

resource "aws_eip" "client" {
  # run this resource only when var.is_client_public_ip_required is true
  count = var.is_client_public_ip_required ? 1 : 0

  vpc               = true
  network_interface = aws_network_interface.client.id

  # Need to add explicit dependency to avoid binding to ENI when in an invalid state
  depends_on = [aws_instance.citrix_adc]

  tags = {
    Name = "${var.deploy_prefix}-Public Data IP (VIP)"
  }
}

