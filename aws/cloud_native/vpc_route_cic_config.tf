#resource "aws_route_table" "cic_to_reach_adc" {
#  vpc_id = aws_vpc.terraform.id
#
#  route {
#    cidr_block = var.cic_config_snip_cidr
#    network_interface_id = element(aws_network_interface.server.*.id, 0)
#  }
#
#  tags = {
#    Name = format("%s Route for CIC to Reach Citrix ADC for Configuration", var.naming_prefix)
#  }
#
#  depends_on = [null_resource.setup_ha_pair]
#}
