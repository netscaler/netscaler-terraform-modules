# =============================================================================
# Progress markers
#
# Terraform reports per-resource progress ("Creation complete after 45s") but
# nothing about where the apply is as a whole, which is unhelpful on a run that
# takes 20+ minutes and spends most of it inside two resources that print
# nothing while they poll.
#
# These print a timestamped line as each phase completes.
#
# They are inert by construction: each one depends on real resources, NOTHING
# depends on them, and they create no infrastructure. They cannot change what
# is built, or in what order. Deleting this file loses the logging and changes
# nothing else.
#
# terraform_data rather than null_resource, deliberately -- it is built into
# Terraform 1.4+, so it adds no provider to required_providers and no download
# to terraform init. versions.tf already requires 1.5.0.
#
# triggers_replace is timestamp(), so every marker re-runs on every apply.
# That is the point -- a marker that only fires once is useless as a progress
# indicator -- but it does mean six trivial changes in every plan. Set
# progress_logs = false to silence them.
# =============================================================================

locals {
  progress = var.progress_logs ? 1 : 0

  # Printed by the first marker so the run announces its own shape.
  progress_banner = "${local.node_count} node(s), cluster ${var.cluster_id}, CLIP ${local.clip}"
}

resource "terraform_data" "progress_instances" {
  count            = local.progress
  depends_on       = [google_compute_instance.adc]
  triggers_replace = timestamp()

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    command     = "printf '\\n==  [%s]  1/6  INSTANCES CREATED  --  ${local.progress_banner}\\n      next: waiting for the VPX management interface to answer NITRO\\n\\n' \"$(date -u +%H:%M:%SZ)\""
  }
}

resource "terraform_data" "progress_boot" {
  count            = local.progress
  depends_on       = [time_sleep.adc_boot]
  triggers_replace = timestamp()

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    command     = "printf '\\n==  [%s]  2/6  BOOT WAIT COMPLETE  --  NSIPs ${join(", ", local.nsips)}\\n      next: resetting nsroot from the GCP instance id on each node\\n\\n' \"$(date -u +%H:%M:%SZ)\""
  }
}

# Same dependency as cluster.tf, so this marker can never fire before the last
# reset has finished.
resource "terraform_data" "progress_passwords" {
  count            = local.progress
  triggers_replace = timestamp()

  depends_on = [
    terraform_data.password_reset,
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    command     = "printf '\\n==  [%s]  3/6  PASSWORDS RESET  --  ${local.node_count} node(s)\\n      next: forming the cluster. This is the long one -- node 0 bootstraps as\\n      CCO, then each node joins and REBOOTS. Expect 10-15 min of silence.\\n\\n' \"$(date -u +%H:%M:%SZ)\""
  }
}

resource "terraform_data" "progress_cluster" {
  count            = local.progress
  depends_on       = [citrixadc_cluster.this]
  triggers_replace = timestamp()

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    command     = "printf '\\n==  [%s]  4/6  CLUSTER FORMED  --  all ${local.node_count} node(s) ACTIVE on CLIP ${local.clip}\\n      next: configuring spotted SNIPs on the data-plane NICs\\n\\n' \"$(date -u +%H:%M:%SZ)\""
  }
}

resource "terraform_data" "progress_snips" {
  count            = local.progress
  triggers_replace = timestamp()

  depends_on = [
    citrixadc_nsip.server_snip,
    citrixadc_nsip.client_snip,
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    command     = "printf '\\n==  [%s]  5/6  SNIPS CONFIGURED\\n      next: saving the running config to ns.conf on every node\\n\\n' \"$(date -u +%H:%M:%SZ)\""
  }
}

resource "terraform_data" "progress_saved" {
  count            = local.progress
  depends_on       = [citrixadc_nsconfig_save.cluster]
  triggers_replace = timestamp()

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    command     = "printf '\\n==  [%s]  6/6  CONFIG SAVED  --  deployment complete\\n      verify: terraform output verify_cluster\\n\\n' \"$(date -u +%H:%M:%SZ)\""
  }
}
