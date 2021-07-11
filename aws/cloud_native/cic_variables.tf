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

variable "cic_config_snip" {
  description = "Citrix ADC Private SNIP which will be used by Citrix Ingress Controller to Configure the ADC. Choose an IP outside the VPC CIDR range"
  default     = "10.10.10.10"
}

variable "adc_login_secret_name" {
  description = "Kubernetes Secret that holds the Citrix ADC login credentials"
  default     = "nslogin"
}

variable "ingress_classes" {
  type        = list(any)
  default     = ["citrix"]
  description = "Kubernetes Ingress Classes that the Citrix Ingress Controller will act upon. Provide in a List format."
}

variable "example_application_hostname" {
  description = "Hostname of the sample application that is deployed and exposed via Ingress"
  default     = "cn.citrix-example-terraform-deployment.com"
}

variable "create_cic" {
  description = "Set this variable to false if you don't want to create a CIC deployment"
  default     = true
}

variable "create_sample_app" {
  description = "Set this variable to false if you don't want to create a Sample example microservice"
  default     = true
}

variable "create_eks" {
  description = "Set this variable to false if you don't want to create a the EKS cluster"
  default     = true
}