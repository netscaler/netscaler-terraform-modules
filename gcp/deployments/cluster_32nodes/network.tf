# =============================================================================
# Networks
#
# Each of the ADC's three NICs must sit in a *different* VPC network — GCP does
# not allow two NICs of one instance on the same network — so this deployment
# needs three.
#
# Two modes, selected by var.use_existing_networks:
#   false -> create all three networks and subnets (needs 3 free slots against
#            the 50-network-per-project quota)
#   true  -> look up three networks and subnets that already exist, consuming
#            no quota at all
# =============================================================================

locals {
  create_networks = var.use_existing_networks ? 0 : 1
  lookup_networks = var.use_existing_networks ? 1 : 0
}

# ---------------------------------------------------------------- management

resource "google_compute_network" "management_network" {
  count                   = local.create_networks
  name                    = "${var.prefix}-management-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "management_subnet" {
  count                    = local.create_networks
  name                     = "${var.prefix}-management-subnet"
  ip_cidr_range            = var.management_subnet_cidr_block
  region                   = var.region
  network                  = google_compute_network.management_network[0].id
  private_ip_google_access = true
}

data "google_compute_network" "management" {
  count = local.lookup_networks
  name  = var.existing_management_network
}

data "google_compute_subnetwork" "management" {
  count  = local.lookup_networks
  name   = var.existing_management_subnet
  region = var.region
}

# -------------------------------------------------------------------- client

resource "google_compute_network" "client_network" {
  count                   = local.create_networks
  name                    = "${var.prefix}-client-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "client_subnet" {
  count                    = local.create_networks
  name                     = "${var.prefix}-client-subnet"
  ip_cidr_range            = var.client_subnet_cidr_block
  region                   = var.region
  network                  = google_compute_network.client_network[0].id
  private_ip_google_access = true
}

data "google_compute_network" "client" {
  count = local.lookup_networks
  name  = var.existing_client_network
}

data "google_compute_subnetwork" "client" {
  count  = local.lookup_networks
  name   = var.existing_client_subnet
  region = var.region
}

# -------------------------------------------------------------------- server

resource "google_compute_network" "server_network" {
  count                   = local.create_networks
  name                    = "${var.prefix}-server-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "server_subnet" {
  count                    = local.create_networks
  name                     = "${var.prefix}-server-subnet"
  ip_cidr_range            = var.server_subnet_cidr_block
  region                   = var.region
  network                  = google_compute_network.server_network[0].id
  private_ip_google_access = true
}

data "google_compute_network" "server" {
  count = local.lookup_networks
  name  = var.existing_server_network
}

data "google_compute_subnetwork" "server" {
  count  = local.lookup_networks
  name   = var.existing_server_subnet
  region = var.region
}

# =============================================================================
# Firewall rules
#
# Firewall rules are quota-cheap and purely additive, but when attached to a
# shared network they affect everyone on it. Set create_firewall_rules = false
# if the existing networks already permit what the cluster needs.
# =============================================================================

resource "google_compute_firewall" "management_firewall" {
  count     = var.create_firewall_rules ? 1 : 0
  name      = "${var.prefix}-management-firewall"
  network   = local.management_network_name
  priority  = 1000
  direction = "INGRESS"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "3008", "3009", "3010", "3011"]
  }

  # Admin and Terraform traffic only. Node-to-node traffic needs far more than
  # this list and gets its own rule below.
  source_ranges = [var.controlling_subnet]
}

# The management subnet is also the cluster backplane: 0/1 is the only ADC
# interface that comes up with an address, so heartbeats and steering tunnels
# ride it. See the precondition in adc_instances.tf.
#
# This has to be permissive. The earlier management rule listed icmp plus a
# handful of TCP ports and no UDP at all, which silently dropped every UDP
# steering packet between nodes -- the apply then spent 30 minutes waiting for
# a node to go ACTIVE and failed with a bare timeout. Scoped to the management
# CIDR, so it opens nothing beyond the three nodes to each other.
resource "google_compute_firewall" "management_backplane_firewall" {
  count     = var.create_firewall_rules ? 1 : 0
  name      = "${var.prefix}-management-backplane-firewall"
  network   = local.management_network_name
  priority  = 900
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

  # GRE, for cluster_tunnel_mode = "GRE".
  allow {
    protocol = "47"
  }

  source_ranges = [local.management_cidr]
}

resource "google_compute_firewall" "client_firewall" {
  count     = var.create_firewall_rules ? 1 : 0
  name      = "${var.prefix}-client-firewall"
  network   = local.client_network_name
  priority  = 1000
  direction = "INGRESS"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# The server subnet doubles as the cluster backplane, so it carries steering
# tunnels between nodes in addition to backend traffic.
resource "google_compute_firewall" "server_firewall" {
  count     = var.create_firewall_rules ? 1 : 0
  name      = "${var.prefix}-server-firewall"
  network   = local.server_network_name
  priority  = 1000
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

  source_ranges = [local.server_cidr]
}

# Steering traffic between cluster nodes when cluster_tunnel_mode = "GRE".
# GRE is IP protocol 47. Unused under UDP or NONE tunnel modes, but harmless.
resource "google_compute_firewall" "cluster_backplane_firewall" {
  count     = var.create_firewall_rules ? 1 : 0
  name      = "${var.prefix}-cluster-backplane-firewall"
  network   = local.server_network_name
  priority  = 900
  direction = "INGRESS"

  allow {
    protocol = "47"
  }

  source_ranges = [local.server_cidr]
}

# =============================================================================
# Warnings, not errors — these are the two configurations that produced a
# successful plan, built every resource, and then failed minutes later on an
# i/o timeout that gave no hint of the real cause.
# =============================================================================

check "terraform_can_reach_the_nsips" {
  assert {
    condition = var.use_existing_networks || var.peer_network != "" || length(var.node_endpoints) > 0
    error_message = join(" ", [
      "Creating brand-new VPC networks with no peering and no node_endpoints override.",
      "A new VPC is isolated: the machine running Terraform will have no route to the NSIPs,",
      "and the apply will build all three instances and then fail on the password reset.",
      "Set peer_network to the network the Terraform host is on, or run Terraform from inside",
      "the new management VPC.",
    ])
  }
}

check "new_networks_have_firewall_rules" {
  assert {
    condition = var.use_existing_networks || var.create_firewall_rules
    error_message = join(" ", [
      "Creating new VPC networks with create_firewall_rules = false.",
      "A new network permits no ingress at all, so NITRO, SSH and the cluster backplane",
      "will all be dropped. create_firewall_rules = false is only for existing networks",
      "that already carry suitable rules.",
    ])
  }
}

# =============================================================================
# External addresses
#
# One management address per node, off by default. Client addresses are
# per-node too: a cluster VIP is striped across every node, so there is no
# single external address that represents the cluster.
# =============================================================================

resource "google_compute_address" "management_external_address" {
  count        = var.assign_management_external_ip ? local.node_count : 0
  name         = "${var.prefix}-management-external-address-${count.index}"
  address_type = "EXTERNAL"
  region       = var.region
}

resource "google_compute_address" "client_external_address" {
  count        = var.assign_client_external_ip ? local.node_count : 0
  name         = "${var.prefix}-client-external-address-${count.index}"
  address_type = "EXTERNAL"
  region       = var.region
}
