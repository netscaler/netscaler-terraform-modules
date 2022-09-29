resource "null_resource" "provision_license" {

    count = var.provision_license ? 1:0

    provisioner "local-exec" {
	command = join(" ", [
		"./provision_license.py",
		"--nsip ${aws_eip.nsip.public_ip}",
		"--nitro-user nsroot",
		"--nitro-pass ${aws_instance.citrix_adc.id}",
		"--license-server-ip ${var.license_server_ip}",
		"--license-server-port ${var.license_server_port}",
		"--license-mode ${var.license_mode}",
		"--bandwidth ${var.bandwidth}",
		"--edition ${var.edition}",
                var.check_reachability ? "--check-reachability": "",
	])
    }
}
