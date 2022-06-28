resource "aws_key_pair" "deployer" {
  count      = var.is_new_keypair_required ? 1 : 0
  key_name   = var.keypair_name
  public_key = file(var.keypair_filepath)
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "bastion_host" {
  vpc_id      = var.vpc_id
  name        = "${var.deploy_prefix}-BastionManagementSG"
  description = "Allow everything from within the VPC and allow only SSH, HTTP, HTTPS access restricted access"

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.deploy_prefix}-BastionHost Management Security Group"
  }
}
resource "aws_network_interface" "bastion_management" {
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.bastion_host.id]

  tags = {
    Name = "${var.deploy_prefix}-BastionHost Management Interface"
  }
}

resource "aws_instance" "this" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = var.is_new_keypair_required ? aws_key_pair.deployer[0].key_name : var.keypair_name

  network_interface {
    network_interface_id = aws_network_interface.bastion_management.id
    device_index         = 0
  }

  tags = {
    Name = "${var.deploy_prefix}-BastionHost"
  }
}


resource "aws_eip" "bastion_host" {
  vpc               = true
  network_interface = aws_instance.this.primary_network_interface_id

  # Need to add explicit dependency to avoid binding to ENI when in an invalid state
  depends_on = [aws_instance.this]

  tags = {
    Name = "${var.deploy_prefix}-BastionHostPublicIP"
  }
}
