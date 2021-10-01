resource "google_compute_instance" "default" {
  name         = "ubuntuinstance"
  machine_type = "e2-standard-4"
  zone         = var.zone


  boot_disk {
    device_name = "boot"
    auto_delete = true
    initialize_params {
      image = "ubuntu-2004-focal-v20210510"
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_ssh_key_file)}"
  }

  # Management NIC
  network_interface {
    subnetwork = var.management_subnet_name
    access_config {
      nat_ip = google_compute_address.ubuntu_management_address.address
    }
  }

  # Client NIC
  network_interface {
    subnetwork = var.client_subnet_name
  }

  # Server NIC
  network_interface {
    subnetwork = var.server_subnet_name
  }
}

resource "google_compute_address" "ubuntu_management_address" {
  name         = "ubuntu-management-address"
  address_type = "EXTERNAL"
  region       = var.region
}
