output "primary_public_nsip" {
  value = google_compute_address.management_external_address[0].address
}

output "secondary_public_nsip" {
  value = google_compute_address.management_external_address[1].address
}
