output "primary_public_nsip" {
  value = google_compute_address.management_external_address[0].address
}

output "secondary_public_nsip" {
  value = google_compute_address.management_external_address[1].address
}
output "public_vip" {
  value = google_compute_address.client_external_address.address
}

output "primary_private_nsip" {
  value = google_compute_instance.adc_primary.network_interface[0].network_ip
}

output "primary_private_vip" {
  value = google_compute_instance.adc_primary.network_interface[1].network_ip
}

output "primary_private_snip" {
  value = google_compute_instance.adc_primary.network_interface[2].network_ip
}

output "secondary_private_nsip" {
  value = google_compute_instance.adc_secondary.network_interface[0].network_ip
}

output "secondary_private_vip" {
  value = google_compute_instance.adc_secondary.network_interface[1].network_ip
}

output "secondary_private_snip" {
  value = google_compute_instance.adc_secondary.network_interface[2].network_ip
}

output "primary_compute_node_id" {
  value = google_compute_instance.adc_primary.instance_id
}
output "secondary_compute_node_id" {
  value = google_compute_instance.adc_secondary.instance_id
}
