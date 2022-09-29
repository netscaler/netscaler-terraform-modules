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

variable "vpx_ami_map" {
  description = <<EOF

AMI map for VPX
Defaults to VPX Express 12.1-51.20

EOF


  default = {
    "ap-northeast-1" = "ami-02454e34c1d7d6b22"
    "ap-northeast-2" = "ami-0fa0efa416deb27c1"
    "ap-south-1"     = "ami-0fde08f60b42ea96f"
    "ap-southeast-1" = "ami-0803c80c209abd277"
    "ap-southeast-2" = "ami-01d523722c729c948"
    "ca-central-1"   = "ami-0ee43001be430451d"
    "eu-central-1"   = "ami-09c314e7d378b3ab7"
    "eu-west-1"      = "ami-03d2a8e34f015d104"
    "eu-west-2"      = "ami-039541dfcf995a477"
    "sa-east-1"      = "ami-063eefb0247cd422d"
    "us-east-1"      = "ami-021d54e00907f90cd"
    "us-east-2"      = "ami-0619cf1188dcd2ec1"
    "us-west-1"      = "ami-00fe4feee9f9b37e2"
    "us-west-2"      = "ami-0cb7a2b575cc622c8"
  }
}

variable "ns_instance_type" {
  description = <<EOF
EC2 instance type.

The following values are allowed:

t2.medium
t2.large
t2.xlarge
t2.2xlarge
m3.large
m3.xlarge
m3.2xlarge
m4.large
m4.xlarge
m4.2xlarge
m4.4xlarge
m4.10xlarge
c4.large
c4.xlarge
c4.2xlarge
c4.4xlarge
c4.8xlarge

EOF


  default = "c4.large"
}

variable "reset_password" {
  description = "Set this to true for first time password reset operation."
  type        = bool
}

variable "new_password" {
  description = "The new ADC password that will replace the default one on both ADC instances. Applicable only when reset_password variable is set to `true`"
}
