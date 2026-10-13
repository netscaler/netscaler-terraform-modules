# =============================================================================
# VPC peering: reaching the NSIPs from wherever Terraform runs
#
# Terraform must talk NITRO to each node's NSIP to reset its password, and to
# the CLIP to form the cluster. When the three networks are created fresh, they
# start completely isolated -- the machine running Terraform is on some other
# VPC and has no route to them at all. That is the single biggest trap in the
# "create new networks" path, and it does not announce itself: the apply gets
# all the way to the password reset and then dies on an i/o timeout.
#
# Peering the new management network to the network Terraform runs on fixes it.
# Set peer_network to that network's name.
#
# Requirements:
#   * The two networks must not have overlapping CIDRs. Peering is refused
#     outright if they do -- this is why the defaults live in 172.20.x rather
#     than the 10.0.x space the rest of the project uses.
#   * You need permission to create a peering on BOTH networks. The reverse
#     peering below modifies the peer network's routing.
#   * Peering does not carry firewall state. The management firewall in
#     network.tf must allow controlling_subnet, which should be the subnet the
#     Terraform host sits in.
#
# Peering is not transitive: only hosts on peer_network itself get a route,
# not anything peered to it in turn.
# =============================================================================

data "google_compute_network" "peer" {
  count = local.create_peering
  name  = var.peer_network
}

resource "google_compute_network_peering" "mgmt_to_peer" {
  count        = local.create_peering
  name         = "${var.prefix}-mgmt-to-peer"
  network      = one(google_compute_network.management_network[*].self_link)
  peer_network = data.google_compute_network.peer[0].self_link
}

# Both directions are required; a one-sided peering stays INACTIVE and routes
# nothing. Sequenced rather than parallel because GCP intermittently rejects
# the second half of a simultaneous pair.
resource "google_compute_network_peering" "peer_to_mgmt" {
  count        = local.create_peering
  name         = "peer-to-${var.prefix}-mgmt"
  network      = data.google_compute_network.peer[0].self_link
  peer_network = one(google_compute_network.management_network[*].self_link)

  depends_on = [google_compute_network_peering.mgmt_to_peer]
}
