output "private_nsip" {
  value = google_compute_instance.default.network_interface[0].network_ip
}

output "private_vip" {
  value = google_compute_instance.default.network_interface[1].network_ip
}

output "private_snip" {
  value = google_compute_instance.default.network_interface[2].network_ip
}
