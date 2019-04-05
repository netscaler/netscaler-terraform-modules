provider "netscaler" {
  endpoint = "${format("http://%v", var.nsip)}"
  username = "${var.username}"
  password = "${var.instance_id}"
}
