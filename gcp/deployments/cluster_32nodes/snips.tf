# =============================================================================
# Spotted SNIPs, and the save that makes everything survive a reboot
#
# GCP puts an address on each instance's nic1 and nic2, but a VPX
# auto-configures only its NSIP, from nic0. Interfaces 1/1 and 1/2 come up with
# no IP at all unless something adds one, which is why the CCO reported "There
# are no spotted SNIPs configured". These are the data-plane addresses: without
# them the appliance can be managed but cannot pass traffic.
#
# "Spotted" means the IP belongs to exactly one node. In cloud it has to be:
# GCP delivers 172.20.3.12 to node 1's nic2 and nowhere else, so a striped SNIP
# would have all three nodes answering for an address only one of them can
# actually receive. ownernode is what makes it spotted, and on a cluster the
# ADC rejects an unspotted one with errorcode 476.
#
# These run against the CLIP (the default provider endpoint) once the cluster
# exists, because that is the point at which ownernode has a meaning -- you
# cannot assign an address to cluster node 1 before cluster node 1 exists.
#
# NOTHING HERE HELPS THE BACKPLANE, and trying to make it was the second failed
# apply. citrixadc_cluster does not return until every node reports ACTIVE, so
# a resource that depends on it cannot run while a node is still stuck
# "(Adding)" for want of a backplane address. The backplane is on 0/1 instead,
# where the NSIP already is. See var.backplane_interface.
# =============================================================================

# Server subnet, for back-end traffic.
resource "citrixadc_nsip" "server_snip" {
  count = var.configure_server_snips ? local.node_count : 0

  ipaddress = local.server_ips[count.index]
  netmask   = local.server_netmask
  type      = "SNIP"
  ownernode = count.index
  icmp      = "ENABLED"

  depends_on = [citrixadc_cluster.this]
}

resource "citrixadc_nsip" "client_snip" {
  count = var.configure_client_snips ? local.node_count : 0

  ipaddress = local.client_ips[count.index]
  netmask   = local.client_netmask
  type      = "SNIP"

  # Pins the address to one node. The index is the node id by construction --
  # local.client_ips is built in node_id order in locals.tf, from the same
  # expression that assigns network_ip on nic1 in adc_instances.tf.
  ownernode = count.index

  # Makes the node answer ping on its client address, which is the quickest
  # way to confirm from inside the VPC that the SNIP actually landed on the
  # node that owns it.
  icmp = "ENABLED"

  depends_on = [citrixadc_cluster.this]
}

# =============================================================================
# Save
#
# Everything above, and everything the cluster resource did, lives in the
# running configuration only. Cluster nodes reboot on their own -- during a CCO
# failover, or when an operator reboots one -- and a node that comes back
# without this config loses its backplane address and drops out again.
#
# A save issued on the CLIP writes ns.conf on every node in the cluster, so one
# of these covers all three.
#
# timestamp is what forces the save to happen again: the resource is otherwise
# unchanged between applies and would be skipped. Keying it on the cluster id
# and the SNIPs means a re-save whenever any of that is rebuilt, and not
# otherwise -- timestamp() itself is deliberately not used, since that would
# produce a permanent diff on every plan.
# =============================================================================

resource "citrixadc_nsconfig_save" "cluster" {
  count = var.save_cluster_config ? 1 : 0

  timestamp = sha1(join(",", concat(
    [tostring(var.cluster_id), local.clip],
    local.nsips,
    local.server_ips,
    var.configure_client_snips ? local.client_ips : [],
  )))

  # Another node in the cluster may be mid-save when this runs -- the join of
  # the last node triggers an internal sync. Retry rather than fail the apply
  # on a transient "save in progress".
  concurrent_save_ok       = true
  concurrent_save_retries  = 5
  concurrent_save_interval = "20s"
  concurrent_save_timeout  = "5m"

  depends_on = [
    citrixadc_cluster.this,
    citrixadc_nsip.server_snip,
    citrixadc_nsip.client_snip,
  ]
}
