variable "machine_type" {
  description = "Instance type. Must allow for 3 NICs"
}

variable "image" {
  description = "Image to use for boot disk. Must be an ADC image."
}
