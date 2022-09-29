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

resource "aws_vpc" "terraform" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "Terraform VPC"
  }
}

resource "aws_subnet" "management" {
  vpc_id                  = aws_vpc.terraform.id
  cidr_block              = var.management_subnet_cidr_blocks[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.aws_availability_zones[count.index]

  tags = {
    Name = format("Terraform Management Subnet Node %v", count.index)
  }

  count = 2
}

resource "aws_subnet" "client" {
  vpc_id                  = aws_vpc.terraform.id
  cidr_block              = var.client_subnet_cidr_blocks[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.aws_availability_zones[count.index]

  tags = {
    Name = format("Terraform Public Subnet Node %v", count.index)
  }

  count = 2
}

resource "aws_subnet" "server" {
  vpc_id            = aws_vpc.terraform.id
  cidr_block        = var.server_subnet_cidr_blocks[count.index]
  availability_zone = var.aws_availability_zones[count.index]

  tags = {
    Name = format("Terraform Server Subnet Node %v", count.index)
  }

  count = 2
}

resource "aws_internet_gateway" "TR_iGW" {
  vpc_id = aws_vpc.terraform.id

  tags = {
    Name = "Terraform Internet Gateway"
  }
}

resource "aws_route_table" "main_rt_table" {
  vpc_id = aws_vpc.terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TR_iGW.id
  }

  tags = {
    Name = "Terraform Main Route Table"
  }
}

resource "aws_main_route_table_association" "TR_main_route" {
  vpc_id         = aws_vpc.terraform.id
  route_table_id = aws_route_table.main_rt_table.id
}


resource "aws_security_group" "management" {
  vpc_id      = aws_vpc.terraform.id
  name        = "Terraform management"
  description = "Allow everything from within the management network and the controlling node."

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = concat([var.controlling_subnet], aws_subnet.management.*.cidr_block)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Terraform Management Security Group"
  }
}

resource "aws_security_group" "client" {
  name        = "Terraform client side"
  description = "Allow Web Traffic from everywhere"

  vpc_id = aws_vpc.terraform.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Terraform Client Security Group"
  }
}

resource "aws_security_group" "server" {
  name        = "Terraform server side"
  description = "Allow all traffic from the server subnet"

  vpc_id = aws_vpc.terraform.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = aws_subnet.server.*.cidr_block
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Terraform Server Security Group"
  }
}
