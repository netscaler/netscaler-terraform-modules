resource "aws_instance" "citrix_adc" {
  ami           = "${lookup(var.vpx_ami_map, var.aws_region)}"
  instance_type = "${var.ns_instance_type}"
  key_name      = "${var.aws_ssh_key_name}"

  network_interface {
    network_interface_id = "${aws_network_interface.management.id}"
    device_index         = 0
  }

  tags {
    Name = "Terraform Citrix ADC"
  }
}

resource "aws_network_interface" "management" {
  subnet_id       = "${aws_subnet.management.id}"
  security_groups = ["${aws_security_group.management.id}"]

  tags {
    Name        = "Terraform NS Management interface"
    Description = "MGMT Interface for Citrix ADC"
  }
}

resource "aws_network_interface" "client" {
  subnet_id       = "${aws_subnet.client.id}"
  security_groups = ["${aws_security_group.client.id}"]

  attachment {
    instance     = "${aws_instance.citrix_adc.id}"
    device_index = 1
  }

  tags {
    Name        = "Terraform NS External Interface"
    Description = "External Interface for Citrix ADC"
  }
}

resource "aws_network_interface" "server" {
  subnet_id       = "${aws_subnet.server.id}"
  security_groups = ["${aws_security_group.server.id}"]

  attachment {
    instance     = "${aws_instance.citrix_adc.id}"
    device_index = 2
  }

  tags {
    Name        = "Terraform NS Internal Interface"
    Description = "Internal Interface for Citrix ADC"
  }
}

resource "aws_eip" "nsip" {
  vpc               = true
  network_interface = "${aws_network_interface.management.id}"

  # Need to add explicit dependency to avoid binding to ENI when in an invalid state
  depends_on = ["aws_instance.citrix_adc"]

  tags {
    Name = "Terraform NSIP"
  }
}

resource "aws_eip" "client" {
  vpc               = true
  network_interface = "${aws_network_interface.client.id}"

  # Need to add explicit dependency to avoid binding to ENI when in an invalid state
  depends_on = ["aws_instance.citrix_adc"]

  tags {
    Name = "Terraform Public Data IP"
  }
}
