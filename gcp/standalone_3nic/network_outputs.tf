output "public_nsip" {
  value = google_compute_address.management_external_address.address
}
output "public_vip" {
  value = google_compute_address.client_external_address.address
}
