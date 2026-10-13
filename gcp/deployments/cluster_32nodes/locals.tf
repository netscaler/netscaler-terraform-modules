locals {
  node_count = var.node_count
  node_ids   = range(local.node_count)

  # Size of the provider-alias pool, and therefore the hard ceiling on
  # node_count. 32 is the NetScaler cluster limit, so this is the appliance's
  # own maximum rather than an artificial one -- var.node_count is the only
  # thing that ever needs changing, at any size.
  #
  # Why a pool at all: citrixadc_password_resetter has no endpoint of its own
  # (its whole schema is username / password / new_password), so the only way
  # to aim it at a particular node is a provider alias. Terraform cannot
  # generate those -- `provider =` cannot be interpolated, and a provider block
  # accepts neither count nor for_each -- so every potential node needs an
  # alias written out in providers.tf and a resetter block in
  # password_reset.tf. Both files hold 32, generated once.
  #
  # Slots at or above node_count cost nothing: their resetter is counted out,
  # their endpoint is loopback, and do_login is false, so nothing is dialled.
  max_nodes = 32

  # Peering only makes sense when we created the management network ourselves.
  # If the networks already existed, whoever owns them owns their routing too.
  create_peering = (!var.use_existing_networks && var.peer_network != "") ? 1 : 0

  # -------------------------------------------------------------------------
  # Resolve networks and subnets from whichever mode is active.
  #
  # one() yields null for an empty (count = 0) list and the single element
  # otherwise, so coalesce picks whichever of the two modes produced a value.
  # A plain ternary would fail here, because indexing the inactive side's
  # empty list errors even on the branch that is not taken.
  # -------------------------------------------------------------------------

  management_network_name = coalesce(
    one(data.google_compute_network.management[*].name),
    one(google_compute_network.management_network[*].name),
  )
  client_network_name = coalesce(
    one(data.google_compute_network.client[*].name),
    one(google_compute_network.client_network[*].name),
  )
  server_network_name = coalesce(
    one(data.google_compute_network.server[*].name),
    one(google_compute_network.server_network[*].name),
  )

  management_subnet_self_link = coalesce(
    one(data.google_compute_subnetwork.management[*].self_link),
    one(google_compute_subnetwork.management_subnet[*].self_link),
  )
  client_subnet_self_link = coalesce(
    one(data.google_compute_subnetwork.client[*].self_link),
    one(google_compute_subnetwork.client_subnet[*].self_link),
  )
  server_subnet_self_link = coalesce(
    one(data.google_compute_subnetwork.server[*].self_link),
    one(google_compute_subnetwork.server_subnet[*].self_link),
  )

  # The CIDRs actually in force on GCP. Used for firewall source ranges and for
  # the precondition that checks them against what the tfvars declared.
  management_cidr = coalesce(
    one(data.google_compute_subnetwork.management[*].ip_cidr_range),
    var.management_subnet_cidr_block,
  )
  client_cidr = coalesce(
    one(data.google_compute_subnetwork.client[*].ip_cidr_range),
    var.client_subnet_cidr_block,
  )
  server_cidr = coalesce(
    one(data.google_compute_subnetwork.server[*].ip_cidr_range),
    var.server_subnet_cidr_block,
  )

  # -------------------------------------------------------------------------
  # Addressing
  #
  # Derived from the *variables*, never from the data sources, so that the
  # citrixadc provider endpoints in providers.tf are known at plan time. A
  # provider configuration cannot depend on a data source read. The precondition
  # in adc_instances.tf catches any mismatch between the declared CIDRs and the
  # real ones.
  # -------------------------------------------------------------------------

  nsips = length(var.nsips) > 0 ? var.nsips : [
    for i in local.node_ids : cidrhost(var.management_subnet_cidr_block, var.nsip_host_offset + i)
  ]

  client_ips = [
    for i in local.node_ids : cidrhost(var.client_subnet_cidr_block, var.data_host_offset + i)
  ]

  server_ips = [
    for i in local.node_ids : cidrhost(var.server_subnet_cidr_block, var.data_host_offset + i)
  ]

  clip = var.clip != "" ? var.clip : cidrhost(var.management_subnet_cidr_block, var.clip_host_offset)

  cluster_api_endpoint = var.cluster_endpoint != "" ? var.cluster_endpoint : "http://${local.clip}"

  # Per-node NITRO endpoints for the password reset. Normally the private
  # NSIPs. The override exists for the case where Terraform can only reach the
  # nodes over pre-reserved external addresses -- those must be reserved out of
  # band and passed in literally, because a provider endpoint cannot be an
  # unknown value at plan time.
  #
  # Note the override does not help the cluster resource: that talks to the
  # CLIP, which is private-only and has no external counterpart. Peering, or
  # running Terraform inside the management VPC, is the only complete answer.
  node_endpoints = length(var.node_endpoints) > 0 ? var.node_endpoints : [
    for ip in local.nsips : "http://${ip}"
  ]

  # One entry per provider alias in providers.tf -- always max_nodes of them,
  # whatever node_count is. Terraform evaluates every provider block in the
  # configuration at plan time, including the ones whose resetter is counted
  # out, so a shorter list fails on an index out of range.
  #
  # Inactive slots get a loopback address rather than a derived one. They are
  # never dialled, and pointing them at cidrhost() output would let a small
  # management subnet break the plan over an alias nothing uses.
  provider_endpoints = [
    for i in range(local.max_nodes) :
    i < local.node_count ? local.node_endpoints[i] : "http://127.0.0.1"
  ]

  # Dotted-quad masks for the ADC. GCP talks CIDR, NITRO wants a netmask.
  client_netmask = cidrnetmask(var.client_subnet_cidr_block)
  server_netmask = cidrnetmask(var.server_subnet_cidr_block)

  # Lowest priority wins the CCO election, so node 0 leads. The base used to be
  # hardcoded at 29, which worked for exactly three nodes and would have put
  # node 3 on priority 32 -- one past what the ADC accepts. A precondition in
  # adc_instances.tf now checks the whole range fits.
  #
  # backplane is "<nodeid>/<interface>", so the default 0/1 gives 0/0/1, 1/0/1,
  # 2/0/1 -- the management interface on each node, which is the only one that
  # has an address. snip_* is the node's nic2 address, reported by the
  # spotted_snips output and configured in snips.tf; it has nothing to do with
  # the backplane any more.
  cluster_nodes = [
    for i in local.node_ids : {
      nodeid       = i
      ip           = local.nsips[i]
      priority     = var.cluster_priority_base + i
      backplane    = "${i}/${var.backplane_interface}"
      snip_address = local.server_ips[i]
      snip_netmask = local.server_netmask
    }
  ]
}
