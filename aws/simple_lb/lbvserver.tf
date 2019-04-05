resource "netscaler_lbvserver" "terraform_test_lb" {
  name        = "terraform_test_lb"
  ipv46       = "${var.vip}"
  port        = "80"
  servicetype = "HTTP"
}

resource "netscaler_servicegroup" "ubuntu_servers" {
  servicegroupname = "terraform_test_servicegroup"
  lbvservers       = ["${netscaler_lbvserver.terraform_test_lb.name}"]
  servicetype      = "HTTP"
  clttimeout       = "40"

  servicegroupmembers = [
    "${format("%v:80", element(aws_network_interface.server_data.*.private_ip, 0))}",
    "${format("%v:80", element(aws_network_interface.server_data.*.private_ip, 1))}",
  ]
}
