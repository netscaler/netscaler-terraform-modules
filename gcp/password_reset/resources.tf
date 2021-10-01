resource "citrixadc_password_resetter" "password_reset" {

    username = "nsroot"
    password = var.default_password
    new_password = var.new_password
}
