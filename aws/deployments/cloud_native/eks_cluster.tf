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

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.24.0"
  cluster_name    = var.cluster_name
  cluster_version = "1.21"
  subnets         = aws_subnet.server.*.id
  # Variable to control EKS creation
  create_eks = var.create_eks

  tags = {
    Environment = "Dev"
    Deployment  = "Citrix-CN-example"
    Vendor      = "Citrix"
  }

  vpc_id = aws_vpc.terraform.id

  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.medium"
      asg_desired_capacity          = 2
      additional_security_group_ids = [aws_security_group.adc_to_worker_nodes.id]
    },
  ]

  depends_on = [
    aws_route_table.nat_gw_route
  ]
}

data "aws_eks_cluster" "cluster" {
  count = var.create_eks ? 1 : 0
  name  = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  count = var.create_eks ? 1 : 0
  name  = module.eks.cluster_id
}

module "cic_deployment" {
  source = "./cic_deployment"

  adc_login_secret_name = var.adc_login_secret_name
  new_password          = var.new_password
  cic_config_snip       = var.cic_config_snip
  ingress_classes       = var.ingress_classes

  count = var.create_cic ? 1 : 0

  depends_on = [
    module.eks
  ]
}

module "sample_app_deployment" {
  source = "./sample_app_deployment"

  frontend_ip                  = element(aws_network_interface.client.*.private_ip, 0)
  ingress_classes              = var.ingress_classes
  ipset_name                   = var.ipset_name
  example_application_hostname = var.example_application_hostname

  count = var.create_sample_app ? 1 : 0

  depends_on = [
    module.eks
  ]
}
