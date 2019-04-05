resource "aws_instance" "ubuntu" {
  ami           = "ami-0883141bc92a74917"
  instance_type = "t2.micro"
  key_name      = "georgen"

  network_interface {
    network_interface_id = "${element(aws_network_interface.server_management.*.id, count.index)}"
    device_index         = 0
  }

  tags = {
    Name = "${format("Terraform Service Node %d", count.index)}"
  }

  count = "${var.count}"
}

resource "null_resource" "networking_setup" {


  connection {
    host = "${element(aws_instance.ubuntu.*.public_ip, count.index)}"
    user = "ubuntu"
  }

  depends_on = ["aws_network_interface.server_data", "aws_instance.ubuntu"]
  provisioner  "remote-exec" {
    inline = [
      "${format("sudo ip addr add dev eth1 %v/24", element(aws_network_interface.server_data.*.private_ip, count.index))}",
      "sudo ip link set eth1 up",
      "sudo apt install -y apache2",
      "${format("sudo bash -c 'echo \"Hello from Terraformed Apache Web Server %v\" > /var/www/html/index.html'", count.index + 1)}",
      "sudo systemctl restart apache2"
    ]
  }

  count = "${var.count}"
}

resource "aws_network_interface" "server_management" {
  subnet_id = "${var.management_subnet_id}"

  security_groups = ["${var.management_security_group_id}"]

  tags = {
    Name = "${format("Terraform Ubuntu Management %d", count.index)}"
  }

  count = "${var.count}"
}

resource "aws_network_interface" "server_data" {
  subnet_id       = "${var.server_subnet_id}"
  security_groups = ["${var.server_security_group_id}"]

  tags = {
    Name = "${format("Terraform Ubuntu Data %d", count.index)}"
  }

  attachment {
    instance     = "${element(aws_instance.ubuntu.*.id, count.index)}"
    device_index = 1
  }

  count = "${var.count}"
}
