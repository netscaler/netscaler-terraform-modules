resource "google_compute_address" "primary_mgmt_address" {
    name = "primary-mgmt-address"
    address_type = "INTERNAL"
    subnetwork = google_compute_subnetwork.management_subnet.id
    region = var.region
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
        add ns ip ${var.vip_alias_range} ${cidrnetmask(var.client_subnet_cidr_block)} -type VIP
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
          "cloud-platform"
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
    alias_ip_range {
      ip_cidr_range = format("%s/%s",var.vip_alias_range, 32)
    }
  }

  # Server NIC
  network_interface {
    subnetwork = google_compute_subnetwork.server_subnet.name
    network_ip = google_compute_address.primary_server_address.address
  }
}

resource "google_compute_address" "secondary_mgmt_address" {
    name = "secondary-mgmt-address"
    address_type = "INTERNAL"
    subnetwork = google_compute_subnetwork.management_subnet.id
    region = var.region
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
        add ns ip ${var.vip_alias_range} ${cidrnetmask(var.client_subnet_cidr_block)} -type VIP
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
          "cloud-platform"
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
  }

  # Server NIC
  network_interface {
    subnetwork = google_compute_subnetwork.server_subnet.name
    network_ip = google_compute_address.secondary_server_address.address
  }

  # Force ordering so primary node selection is deterministic 
  depends_on = [google_compute_instance.adc_primary]
}

