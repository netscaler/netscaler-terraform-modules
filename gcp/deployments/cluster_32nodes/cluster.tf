# =============================================================================
# Three-Node NetScaler Cluster
# =============================================================================
#
# The composite citrixadc_cluster resource handles, in order:
#   1. Bootstrapping node 0 as the Cluster Configuration Coordinator (CCO)
#   2. Creating the Cluster IP (CLIP)
#   3. Declaring each remaining node on the CLIP, then joining it
#
# Step 3 is where this resource blocks, and the shape of that block dictates
# the rest of the configuration. After joining a node it polls the CLIP until
# that node's masterstate reads ACTIVE, and it does not return until every node
# does. So there is no "after the cluster forms, but before the nodes have to
# be healthy" moment -- any resource that depends on this one runs strictly
# after all three nodes are already working.
#
# That rules out fixing an unhealthy node from Terraform. A node whose
# backplane has no IP never leaves "(Adding)", the poll runs out its 30 minutes
# and the apply dies on a bare "timeout waiting for cluster operation to
# complete". The SNIP that would have given it an address sits unapplied in the
# graph behind the very resource that is waiting for it. Hence the backplane on
# 0/1, which has the NSIP on it already: see var.backplane_interface.
#
# The node with the lowest priority value becomes the CCO. Priority is computed
# in locals.tf as 29 + node_id, so node 0 leads.
# =============================================================================

resource "citrixadc_cluster" "this" {
  clid          = var.cluster_id
  clip          = local.clip
  hellointerval = var.hello_interval

  # Both "enable cluster instance" on the CCO and each subsequent node join
  # REBOOT the node in question, and the provider then polls until it returns.
  # Budget for that reboot, not for an API call: this VPX needs the full 10
  # minutes of var.adc_boot_wait just to come up cold, so the provider's 10m
  # default expires while the node is still booting and the bootstrap is
  # reported as failed even when it is merely slow.
  #
  # poll_delay is dead time before the first poll -- no point asking a node
  # that is still in its reboot. poll_timeout is the per-request HTTP timeout;
  # the 10s default is tight for a VPX that is mid-boot and answering slowly,
  # and a timed-out poll is indistinguishable from a refused one.
  bootstrap_poll_delay    = "180s"
  bootstrap_poll_interval = "30s"
  bootstrap_poll_timeout  = "30s"
  bootstrap_total_timeout = "30m"
  node_add_poll_delay     = "180s"
  node_add_poll_interval  = "30s"
  node_add_total_timeout  = "30m"

  dynamic "clusternode" {
    for_each = local.cluster_nodes
    content {
      nodeid     = clusternode.value.nodeid
      endpoint   = "http://${clusternode.value.ip}"
      ipaddress  = clusternode.value.ip
      backplane  = clusternode.value.backplane
      priority   = clusternode.value.priority
      state      = "ACTIVE"
      tunnelmode = var.cluster_tunnel_mode
      nodegroup  = "DEFAULT_NG"

      # Credentials for the per-node NITRO calls. These default to the provider
      # block, but the provider block points at the CLIP and these calls go to
      # the node's own NSIP, so set them explicitly rather than rely on the
      # fallback.
      username = var.adc_admin_username
      password = var.adc_admin_password

      # -----------------------------------------------------------------------
      # addsnip is deliberately NOT set here, and must not be.
      #
      # It looks like exactly what this deployment needs -- it adds the node's
      # backplane address to the CLIP as a SNIP before the node joins -- but it
      # is broken in the provider. From resource_citrixadc_cluster.go:
      #
      #     if raw := d.GetRawConfig().GetAttr("ownernode"); !raw.IsNull() {
      #         nodeNsip.Ownernode = intPtr(d.Get("ownernode").(int))
      #     }
      #
      # d is the top-level cluster resource, and "ownernode" is not in that
      # resource's schema -- those two lines are its only occurrences in the
      # file. The branch is therefore never taken, Ownernode is never set, and
      # the SNIP goes to the appliance unspotted. The Framework rewrite in
      # citrixadc_framework/cluster/resource_cluster.go does not even attempt
      # it: its addsnip payload has no Ownernode field at all. On a cluster the
      # ADC refuses an unspotted SNIP outright:
      #
      #     errorcode 476, "Owner node is not specified."
      #
      # which is what killed the apply. No value in this configuration can
      # change it. The backplane SNIPs are created in snips.tf instead, as
      # citrixadc_nsip resources, where ownernode can actually be supplied.
      # -----------------------------------------------------------------------
    }
  }

  # The whole 32-slot resetter pool, not just the active nodes. depends_on on a
  # resource with count = 0 is simply satisfied, so the inactive ones cost
  # nothing, and listing all of them means changing node_count can never leave
  # a node unreset. That failure would not look like a missing dependency: it
  # would surface half an hour later as this resource timing out against a node
  # still holding its GCP instance id as its password.
  depends_on = [
    citrixadc_password_resetter.node0,
    citrixadc_password_resetter.node1,
    citrixadc_password_resetter.node2,
    citrixadc_password_resetter.node3,
    citrixadc_password_resetter.node4,
    citrixadc_password_resetter.node5,
    citrixadc_password_resetter.node6,
    citrixadc_password_resetter.node7,
    citrixadc_password_resetter.node8,
    citrixadc_password_resetter.node9,
    citrixadc_password_resetter.node10,
    citrixadc_password_resetter.node11,
    citrixadc_password_resetter.node12,
    citrixadc_password_resetter.node13,
    citrixadc_password_resetter.node14,
    citrixadc_password_resetter.node15,
    citrixadc_password_resetter.node16,
    citrixadc_password_resetter.node17,
    citrixadc_password_resetter.node18,
    citrixadc_password_resetter.node19,
    citrixadc_password_resetter.node20,
    citrixadc_password_resetter.node21,
    citrixadc_password_resetter.node22,
    citrixadc_password_resetter.node23,
    citrixadc_password_resetter.node24,
    citrixadc_password_resetter.node25,
    citrixadc_password_resetter.node26,
    citrixadc_password_resetter.node27,
    citrixadc_password_resetter.node28,
    citrixadc_password_resetter.node29,
    citrixadc_password_resetter.node30,
    citrixadc_password_resetter.node31,
    time_sleep.adc_boot,
  ]
}
