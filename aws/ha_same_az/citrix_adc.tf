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
    network_interface_id = element(aws_network_interface.management.*.id, count.index)
    device_index         = 0
  }

  availability_zone = var.aws_availability_zone

  iam_instance_profile = aws_iam_instance_profile.citrix_adc_ha_instance_profile.name

  tags = {
    Name = format("Citrix ADC HA Node %v", count.index)
  }

  count = 2
}

resource "aws_iam_role_policy" "citrix_adc_ha_policy" {
  name = "citrix_adc_ha_policy"
  role = aws_iam_role.citrix_adc_ha_role.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DetachNetworkInterface",
        "ec2:AttachNetworkInterface",
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:RebootInstances",
        "autoscaling:*",
        "sns:*",
        "iam:SimulatePrincipalPolicy",
        "iam:GetRole",
        "sqs:*"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role" "citrix_adc_ha_role" {
  name = "citrix_adc_ha_role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      }
    }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "citrix_adc_ha_instance_profile" {
name = "citrix_adc_ha_instance_profile"
path = "/"
role = aws_iam_role.citrix_adc_ha_role.name
}

resource "aws_network_interface" "management" {
subnet_id       = aws_subnet.management.id
security_groups = [aws_security_group.management.id]

tags = {
Name = format("Citrix ADC Management Interface HA Node %v", count.index)
}

count = 2
}

resource "aws_network_interface" "client" {
subnet_id       = aws_subnet.client.id
security_groups = [aws_security_group.client.id]

attachment {
instance     = element(aws_instance.citrix_adc.*.id, 0)
device_index = 1
}

tags = {
Name = "Citrix ADC Client Interface"
}
}

resource "aws_network_interface" "server" {
subnet_id       = aws_subnet.server.id
security_groups = [aws_security_group.server.id]

attachment {
instance     = element(aws_instance.citrix_adc.*.id, 0)
device_index = 2
}

tags = {
Name = "Citrix ADC Server Interface"
}
}

resource "aws_eip" "nsip" {
vpc               = true
network_interface = element(aws_network_interface.management.*.id, count.index)

# Need to add explicit dependency to avoid binding to ENI when in an invalid state
depends_on = [aws_instance.citrix_adc]

tags = {
Name = format("Citrix ADC NSIP HA Node %v", count.index)
}

count = 2
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
