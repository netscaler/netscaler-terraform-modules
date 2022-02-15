# SSL Service 1
variable "ssl_service1_name" {
  default = "service-ssl-1"
}

variable "ssl_service1_ip" {
}

# SSL Service 2
variable "ssl_service2_name" {
  default = "service-ssl-2"
}

variable "ssl_service2_ip" {
}

# Production SSL LB Vservice
variable "production_lb_name" {
  default = "vserver-ssl"
}

variable "production_lb_ip" {
}

# SSL CertKey
variable "ssl_certkey_name" {
  default = "ssl-certkey1"
}

variable "ssl_certificate_path" {
}

variable "ssl_key_path" {
}
