output "public_management_ip" {
  value = google_compute_address.ubuntu_management_address.address
}
