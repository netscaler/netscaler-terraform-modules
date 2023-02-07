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
  }

  allow {
    protocol = "udp"
    ports = ["3003"]
  }

  source_ranges = [ var.controlling_subnet, google_compute_subnetwork.management_subnet.ip_cidr_range ]

}

resource "google_compute_subnetwork" "management_subnet" {
  name          = var.management_subnet_name
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
  name          = var.client_subnet_name
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
  name          = var.server_subnet_name
  ip_cidr_range = var.server_subnet_cidr_block
  region        = var.region
  network       = google_compute_network.server_network.id
  private_ip_google_access = true
}


resource "google_compute_address" "management_external_address" {
  name         = format("management-external-address-%d", count.index)
  address_type = "EXTERNAL"
  region       = var.region
  count = 2
}

resource "google_compute_address" "client_external_address" {
  name         = "client-external-address"
  address_type = "EXTERNAL"
  region       = var.region
}

resource "google_compute_address" "primary_mgmt_address" {
  name         = "primary-mgmt-address"
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.management_subnet.id
  region       = var.region
}
resource "google_compute_address" "primary_client_address" {
  name         = "primary-client-address"
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.client_subnet.id
  region       = var.region
}
resource "google_compute_address" "primary_server_address" {
  name         = "primary-server-address"
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.server_subnet.id
  region       = var.region
}

resource "google_compute_instance" "adc_primary" {
  name         = "adcinstance-primary"
  machine_type = var.machine_type
  zone         = var.zones[0]


  boot_disk {
    device_name = "boot"
    auto_delete = true
    initialize_params {
      image = var.image
    }
  }

  metadata_startup_script = <<-EOF
    <NS-PRE-BOOT-CONFIG>
      <NS-CONFIG>
        set systemparameter -promptString "%u@%s"
        add ns ip ${google_compute_address.primary_server_address.address} ${cidrnetmask(var.server_subnet_cidr_block)} -type SNIP
        add ns ip ${google_compute_address.primary_client_address.address} ${cidrnetmask(var.client_subnet_cidr_block)} -type VIP
        add ns ip ${google_compute_address.secondary_client_address.address} ${cidrnetmask(var.client_subnet_cidr_block)} -type VIP
        add ha node 1 ${google_compute_address.secondary_mgmt_address.address} -inc ENABLED
        set ns rpcNode ${google_compute_address.primary_mgmt_address.address} -password ${var.citrixadc_rpc_node_password} -secure YES
        set ns rpcNode ${google_compute_address.secondary_mgmt_address.address} -password ${var.citrixadc_rpc_node_password} -secure YES
      </NS-CONFIG>
    </NS-PRE-BOOT-CONFIG>
  EOF
  
  metadata = {
    ssh-keys = "nsroot:${file(var.public_ssh_key_file)}"
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  # Management NIC
  network_interface {
    subnetwork = google_compute_subnetwork.management_subnet.name
    network_ip = google_compute_address.primary_mgmt_address.address
    access_config {
      nat_ip = google_compute_address.management_external_address[0].address
    }
  }

  # Client NIC
  network_interface {
    subnetwork = google_compute_subnetwork.client_subnet.name
    network_ip = google_compute_address.primary_client_address.address
    access_config {
      nat_ip = google_compute_address.client_external_address.address
    }
  }

  # Server NIC
  network_interface {
    subnetwork = google_compute_subnetwork.server_subnet.name
    network_ip = google_compute_address.primary_server_address.address
  }
}

resource "google_compute_address" "secondary_mgmt_address" {
  name         = "secondary-mgmt-address"
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.management_subnet.id
  region       = var.region
}
resource "google_compute_address" "secondary_client_address" {
  name         = "secondary-client-address"
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.client_subnet.id
  region       = var.region
}
resource "google_compute_address" "secondary_server_address" {
  name         = "secondary-server-address"
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.server_subnet.id
  region       = var.region
}

resource "google_compute_instance" "adc_secondary" {
  name         = "adcinstance-secondary"
  machine_type = var.machine_type
  zone         = var.zones[1]


  boot_disk {
    device_name = "boot"
    auto_delete = true
    initialize_params {
      image = var.image
    }
  }

  metadata_startup_script = <<-EOF
    <NS-PRE-BOOT-CONFIG>
      <NS-CONFIG>
        set systemparameter -promptString "%u@%s"
        add ns ip ${google_compute_address.secondary_server_address.address} ${cidrnetmask(var.server_subnet_cidr_block)} -type SNIP
        add ns ip ${google_compute_address.secondary_client_address.address} ${cidrnetmask(var.client_subnet_cidr_block)} -type VIP
        add ns ip ${google_compute_address.primary_client_address.address} ${cidrnetmask(var.client_subnet_cidr_block)} -type VIP
        add ha node 1 ${google_compute_address.primary_mgmt_address.address} -inc ENABLED
        set ns rpcNode ${google_compute_address.primary_mgmt_address.address} -password ${var.citrixadc_rpc_node_password} -secure YES
        set ns rpcNode ${google_compute_address.secondary_mgmt_address.address} -password ${var.citrixadc_rpc_node_password} -secure YES
      </NS-CONFIG>
    </NS-PRE-BOOT-CONFIG>
  EOF
  
  metadata = {
    ssh-keys = "nsroot:${file(var.public_ssh_key_file)}"
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  # Management NIC
  network_interface {
    subnetwork = google_compute_subnetwork.management_subnet.name
    network_ip = google_compute_address.secondary_mgmt_address.address
    access_config {
      nat_ip = google_compute_address.management_external_address[1].address
    }
  }

  # Client NIC
  network_interface {
    subnetwork = google_compute_subnetwork.client_subnet.name
    network_ip = google_compute_address.secondary_client_address.address
  }

  # Server NIC
  network_interface {
    subnetwork = google_compute_subnetwork.server_subnet.name
    network_ip = google_compute_address.secondary_server_address.address
  }

  # Force ordering so primary node selection is deterministic 
  depends_on = [google_compute_instance.adc_primary]
}
