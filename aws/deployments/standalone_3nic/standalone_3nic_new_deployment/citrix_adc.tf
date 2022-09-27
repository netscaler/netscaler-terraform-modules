########################################################################################
#
#  Copyright (c) 2019 Citrix Systems, Inc.
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#      * Redistributions of source code must retain the above copyright
#        notice, this list of conditions and the following disclaimer.
#      * Redistributions in binary form must reproduce the above copyright
#        notice, this list of conditions and the following disclaimer in the
#        documentation and/or other materials provided with the distribution.
#      * Neither the name of the Citrix Systems, Inc. nor the
#        names of its contributors may be used to endorse or promote products
#        derived from this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL Citrix Systems, Inc. BE LIABLE FOR ANY
#  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
########################################################################################

resource "aws_instance" "citrix_adc" {
  ami           = var.vpx_ami_map[var.aws_region]
  instance_type = var.ns_instance_type
  key_name      = var.aws_ssh_key_name

  network_interface {
    network_interface_id = aws_network_interface.management.id
    device_index         = 0
  }

  tags = {
    Name = "Terraform Citrix ADC"
  }
}

resource "aws_network_interface" "management" {
  subnet_id       = aws_subnet.management.id
  security_groups = [aws_security_group.management.id]

  tags = {
    Name        = "Terraform NS Management interface"
    Description = "MGMT Interface for Citrix ADC"
  }
}

resource "aws_network_interface" "client" {
  subnet_id       = aws_subnet.client.id
  security_groups = [aws_security_group.client.id]

  attachment {
    instance     = aws_instance.citrix_adc.id
    device_index = 1
  }

  tags = {
    Name        = "Terraform NS External Interface"
    Description = "External Interface for Citrix ADC"
  }
}

resource "aws_network_interface" "server" {
  subnet_id       = aws_subnet.server.id
  security_groups = [aws_security_group.server.id]

  attachment {
    instance     = aws_instance.citrix_adc.id
    device_index = 2
  }

  tags = {
    Name        = "Terraform NS Internal Interface"
    Description = "Internal Interface for Citrix ADC"
  }
}

resource "aws_eip" "nsip" {
  vpc               = true
  network_interface = aws_network_interface.management.id

  # Need to add explicit dependency to avoid binding to ENI when in an invalid state
  depends_on = [aws_instance.citrix_adc]

  tags = {
    Name = "Terraform NSIP"
  }
}

resource "aws_eip" "client" {
  vpc               = true
  network_interface = aws_network_interface.client.id

  # Need to add explicit dependency to avoid binding to ENI when in an invalid state
  depends_on = [aws_instance.citrix_adc]

  tags = {
    Name = "Terraform Public Data IP"
  }
}
