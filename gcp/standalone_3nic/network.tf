resource "google_compute_network" "management_network" {
  name = "management-network"
  auto_create_subnetworks = false
}

resource "google_compute_firewall" "management_firewall" {
  name    = "management-firewall"
  network = google_compute_network.management_network.name
  priority = 1000
  direction = "INGRESS"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }
  source_ranges = [ var.controlling_subnet, google_compute_subnetwork.management_subnet.ip_cidr_range ]

}

resource "google_compute_subnetwork" "management_subnet" {
  name          = "management-subnet"
  ip_cidr_range = var.management_subnet_cidr_block
  region        = var.region
  network       = google_compute_network.management_network.id
  private_ip_google_access = true
}

resource "google_compute_network" "client_network" {
  name = "client-network"
  auto_create_subnetworks = false
}

resource "google_compute_firewall" "client_firewall" {
  name    = "client-firewall"
  network = google_compute_network.client_network.name
  priority = 1000
  direction = "INGRESS"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = [ "0.0.0.0/0" ]

}

resource "google_compute_subnetwork" "client_subnet" {
  name          = "client-subnet"
  ip_cidr_range = var.client_subnet_cidr_block
  region        = var.region
  network       = google_compute_network.client_network.id
  private_ip_google_access = true
}

resource "google_compute_network" "server_network" {
  name = "server-network"
  auto_create_subnetworks = false
}

resource "google_compute_firewall" "server_firewall" {
  name    = "server-firewall"
  network = google_compute_network.server_network.name
  priority = 1000
  direction = "INGRESS"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
  source_ranges = [ google_compute_subnetwork.server_subnet.ip_cidr_range ]

}

resource "google_compute_subnetwork" "server_subnet" {
  name          = "server-subnet"
  ip_cidr_range = var.server_subnet_cidr_block
  region        = var.region
  network       = google_compute_network.server_network.id
  private_ip_google_access = true
}


resource "google_compute_address" "management_external_address" {
  name         = "management-external-address"
  address_type = "EXTERNAL"
  region       = var.region
}

resource "google_compute_address" "client_external_address" {
  name         = "client-external-address"
  address_type = "EXTERNAL"
  region       = var.region
}
