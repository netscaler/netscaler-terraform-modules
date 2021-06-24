variable "frontend_ip" {
    description = "Frontend IP for the Ingress Configuration"
}

variable "ingress_classes" {
    description = "Ingress Classes for Ingress Configuration"
}

variable "ipset_name" {
    description = "Provide the IPSET name to be used for Frontend Configuration in Ingress"
}

variable "example_application_hostname" {
  description = "Hostname of the sample application that is deployed and exposed via Ingress"
}