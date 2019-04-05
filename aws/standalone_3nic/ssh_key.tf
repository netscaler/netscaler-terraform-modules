resource "aws_key_pair" "general_access_key" {
  key_name   = "${var.aws_ssh_key_name}"
  public_key = "${var.aws_ssh_public_key }"
}
