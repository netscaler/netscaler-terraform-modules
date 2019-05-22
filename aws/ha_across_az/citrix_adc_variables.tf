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

  default = "m4.large"
}
