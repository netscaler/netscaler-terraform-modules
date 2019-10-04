variable "provision_license" {
    description = "Boolean value to determine if provision license script will run."
    default = false
}

variable "license_server_ip" {
    description = "License server ip address."
}

variable "license_server_port" {
    description = "License server port."
    default = 27000
}

variable "license_mode" {
    description = "License mode. Valid values are `cico` `pooled` `vcpu`"
}

variable "reboot" {
    description = "Whether to reboot instance after applying license for changes to take effect."
    default = false
}

variable "platform" {
    description = "Platform for the license."
    default = "Replace with needed value for mode cico"
}

variable "edition" {
    description = "Edition for the license. Valid values are `Platinum` `Standard` `Enterprise`"
    default = "Replace with needed value for mode pooled and vcpu"
}

variable "bandwidth" {
    description = "Bandwidth for the pooled license."
    default = "Replace with needed value for mode pooled"
}

variable "units" {
    description = "Units for the bandwidth. Can be `Gbps` or `Mbps`"
    default = "Mbps"
}

variable "check_reachability" {
    description = "Boolean instructing the provision license script to check for instance reachability before provisioning license"
    default = false
}
