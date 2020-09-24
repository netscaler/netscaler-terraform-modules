resource "null_resource" "password_reset" {
  provisioner "local-exec" {
    environment = {
      WAIT_PERIOD  = var.reset_delay_sec
      NSIP         = aws_eip.nsip.public_ip
      USERNAME     = "nsroot"
      OLD_PASSWORD = aws_instance.citrix_adc.id
      NEW_PASSWORD = var.new_password
      DO_RESET     = var.reset_password
    }
    interpreter = ["bash"]
    command     = "password_reset.sh"
  }

  depends_on = [
    aws_instance.citrix_adc
  ]
}

