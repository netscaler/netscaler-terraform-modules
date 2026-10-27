output "cluster_topology" {
  description = "What this deployment builds, per node. Check it against 'show cluster node' on the CLIP after the apply."
  value = {
    node_count   = local.node_count
    max_nodes    = local.max_nodes
    cco          = "node 0 (${local.nsips[0]}), lowest priority wins the election"
    tunnel_mode  = var.cluster_tunnel_mode
    nodes = {
      for n in local.cluster_nodes : n.nodeid => {
        nsip      = n.ip
        priority  = n.priority
        backplane = n.backplane
        client_ip = local.client_ips[n.nodeid]
        server_ip = local.server_ips[n.nodeid]
      }
    }
  }
}

output "clip" {
  description = "Cluster IP address. Manage the cluster here once it is formed."
  value       = local.clip
}

output "cluster_endpoint" {
  description = "NITRO endpoint the cluster resource talks to"
  value       = local.cluster_api_endpoint
}

output "private_nsips" {
  description = "Per-node NSIP (management NIC), in node_id order"
  value       = google_compute_instance.adc[*].network_interface[0].network_ip
}

output "private_vips" {
  description = "Per-node client NIC address, in node_id order"
  value       = google_compute_instance.adc[*].network_interface[1].network_ip
}

output "private_snips" {
  description = "Per-node server NIC address, in node_id order. Configured as a spotted SNIP by snips.tf; not the backplane, which is on 0/1."
  value       = google_compute_instance.adc[*].network_interface[2].network_ip
}

output "public_nsips" {
  description = "Per-node external management address, in node_id order. Empty when assign_management_external_ip is false."
  value       = google_compute_address.management_external_address[*].address
}

output "networks" {
  description = "The VPC networks in use, and whether they were created or looked up"
  value = {
    mode       = var.use_existing_networks ? "existing" : "created"
    management = local.management_network_name
    client     = local.client_network_name
    server     = local.server_network_name
  }
}

output "public_vips" {
  description = "Per-node external client address, in node_id order. Empty when assign_client_external_ip is false."
  value       = google_compute_address.client_external_address[*].address
}

output "interfaces" {
  description = "ADC interface map. Fixed by NIC order in adc_instances.tf, not configurable on GCP."
  value = {
    management = var.backplane_interface == var.management_interface ? "${var.management_interface} (also backplane)" : var.management_interface
    client     = var.backplane_interface == "1/1" ? "1/1 (also backplane)" : "1/1"
    server     = var.backplane_interface == "1/2" ? "1/2 (also backplane)" : "1/2"
    backplane  = [for n in local.cluster_nodes : n.backplane]
  }
}

output "backplane_interfaces" {
  description = "Interface used as the cluster backplane on each node"
  value       = [for n in local.cluster_nodes : n.backplane]
}

output "instance_settings" {
  description = "Per-instance settings the cluster depends on, read back from GCP so they can be confirmed after apply rather than assumed."
  value = {
    ip_forwarding_enabled = google_compute_instance.adc[*].can_ip_forward
    api_scopes            = distinct(flatten(google_compute_instance.adc[*].service_account[*].scopes))
    service_accounts      = distinct(flatten(google_compute_instance.adc[*].service_account[*].email))
  }
}

output "node_endpoints" {
  description = "NITRO endpoints used for the per-node password reset"
  value       = local.node_endpoints
}

output "peering" {
  description = "VPC peering created so Terraform can reach the NSIPs, if any"
  value = local.create_peering == 1 ? {
    peer_network = var.peer_network
    management   = local.management_network_name
  } : null
}

output "spotted_snips" {
  description = "Per-node data-plane SNIPs configured on the CLIP after the cluster forms. The backplane is not in here: it runs on 0/1 and uses the NSIP, which the ADC configures itself."
  value = {
    server = var.configure_server_snips ? {
      for n in local.cluster_nodes : n.nodeid => "${n.snip_address}/${n.snip_netmask} (ownernode ${n.nodeid}, interface 1/2)"
    } : {}
    client = var.configure_client_snips ? {
      for i in local.node_ids : i => "${local.client_ips[i]}/${local.client_netmask} (ownernode ${i}, interface 1/1)"
    } : {}
  }
}

output "verify_cluster" {
  description = "Run these from a host on the management network once the apply finishes. Every node must read health UP; a node showing (Adding) or UNKNOWN has not really joined."
  value = [
    "ssh nsroot@${local.clip}",
    "  show cluster instance ${var.cluster_id}",
    "  show cluster node",
    "  show ns ip",
    "Expect: 3 nodes, one ACTIVE(Configuration Coordinator), all health UP,",
    "and no 'There are no spotted SNIPs configured' or 'Heartbeats are not seen on backplane' warning.",
  ]
}

output "ssh_commands" {
  description = "Ready-made SSH commands for each node's management interface. Falls back to the private NSIPs when no external management addresses were assigned."
  value = var.assign_management_external_ip ? [
    for i in local.node_ids : "ssh nsroot@${google_compute_address.management_external_address[i].address}"
    ] : [
    for i in local.node_ids : "ssh nsroot@${local.nsips[i]}  # from inside the VPC"
  ]
}
