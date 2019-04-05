variable "vpx_ami_map" {
  description = <<EOF

AMI map for VPX
Defaults to VPX Express 12.1-49.37

EOF

  default = {
    "ap-south-1"     = "ami-0b16b152469f6a0c0"
    "us-east-1"      = "ami-01715a94f5a8cb590"
    "us-east-2"      = "ami-044ab510df4868644"
    "ap-southeast-2" = "ami-0129a5c095a457b4c"
    "ap-northeast-1" = "ami-0cc1b5d18a331ce3c"
    "sa-east-1"      = "ami-06033492560ba1cff"
    "ap-southeast-1" = "ami-0553bb4e1990297b7"
    "ca-central-1"   = "ami-06478b9cc5118cab2"
    "ap-northeast-2" = "ami-0b7bcac5c0e9dda2e"
    "us-west-2"      = "ami-0c10ec275e28106a8"
    "us-west-1"      = "ami-0d7c8111761a1a06c"
    "eu-central-1"   = "ami-09fa73854157f8024"
    "eu-west-1"      = "ami-012499b628793c2f5"
    "eu-west-2"      = "ami-0a2e20b007c7377f9"
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

  default = "m4.large"
}
