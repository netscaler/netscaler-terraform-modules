variable "adc_login_secret_name" {
    description = "Provide the Citrix ADC login Secret Name"
}

variable "new_password" {
    description = "Provide the New Password for Citrix ADC"
}

variable "cic_config_snip" {
    description = "Provide the NS_IP to be used in CIC deployment"  
}

variable "ingress_classes" {
    description = "Ingress Classes for Ingress Configuration"
}