
resource "aws_security_group" "adc_to_worker_nodes" {
  name_prefix = "allow_adc_to_worker_nodes"
  vpc_id      = aws_vpc.terraform.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    security_groups = [
      aws_security_group.server.id
    ]
  }
}
