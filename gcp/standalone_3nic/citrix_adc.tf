resource "google_compute_instance" "default" {
  name         = "adcinstance"
  machine_type = var.machine_type
  zone         = var.zone


  boot_disk {
    device_name = "boot"
    auto_delete = true
    initialize_params {
      image = var.image
    }
  }

  metadata = {
    ssh-keys = "nsroot:${file(var.public_ssh_key_file)}"
  }

  # Management NIC
  network_interface {
    subnetwork = google_compute_subnetwork.management_subnet.name
    access_config {
      nat_ip = google_compute_address.management_external_address.address
    }
  }

  # Client NIC
  network_interface {
    subnetwork = google_compute_subnetwork.client_subnet.name
    access_config {
      nat_ip = google_compute_address.client_external_address.address
    }
  }

  # Server NIC
  network_interface {
    subnetwork = google_compute_subnetwork.server_subnet.name
  }
  allow_stopping_for_update = true
  service_account {
    scopes = ["cloud-platform"]
  }
}

