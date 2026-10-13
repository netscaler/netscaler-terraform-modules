resource "google_compute_instance" "adc" {
  count        = local.node_count
  name         = "${var.prefix}-node-${count.index}"
  machine_type = var.machine_type
  zone         = var.zone

  # "Enable IP forwarding" in the console. Not optional and not exposed as a
  # variable: GCP drops any packet whose source or destination is not the NIC's
  # own address unless this is set, which would break every address the cluster
  # floats rather than owns -- the CLIP, the striped VIPs, and the GRE or UDP
  # steering tunnels between nodes. It can only be set at creation time;
  # changing it forces the instance to be replaced.
  can_ip_forward = true

  # Empty by default. Only needed when the target networks have tag-scoped
  # firewall rules; see the network_tags variable.
  tags = var.network_tags

  boot_disk {
    device_name = "boot"
    auto_delete = true
    initialize_params {
      image = var.image
    }
  }

  # pathexpand handles a leading ~; file() on its own does not expand it.
  metadata = {
    ssh-keys = "nsroot:${file(pathexpand(var.public_ssh_key_file))}"
  }

  # ---------------------------------------------------------------------------
  # NIC order is significant and must not be rearranged. GCP attaches these in
  # declaration order, and the VPX maps them to its own interfaces positionally:
  #
  #   nic0 -> ADC 0/1  management (NSIP)   <- var.management_interface
  #   nic1 -> ADC 1/1  client     (VIP)
  #   nic2 -> ADC 1/2  server     (SNIP + cluster backplane)
  #
  # There is no way to tell a VPX on GCP to use a different NIC for management;
  # the first one always wins. var.backplane_interface indexes into this same
  # scheme, which is why "1/2" means the server NIC.
  # ---------------------------------------------------------------------------

  # nic0 -> 0/1 management, NSIP pinned so provider endpoints resolve at plan time
  network_interface {
    subnetwork = local.management_subnet_self_link
    network_ip = local.nsips[count.index]

    dynamic "access_config" {
      for_each = var.assign_management_external_ip ? [1] : []
      content {
        nat_ip = google_compute_address.management_external_address[count.index].address
      }
    }

    # The CLIP is a floating address the cluster owns, but GCP only delivers to
    # addresses it has been told about. Publishing it as an alias range on the
    # CCO's management NIC makes it reachable from the rest of the VPC.
    dynamic "alias_ip_range" {
      for_each = var.create_clip_alias && count.index == 0 ? [1] : []
      content {
        ip_cidr_range = "${local.clip}/32"
      }
    }
  }

  # nic1 -> 1/1 client, VIP
  network_interface {
    subnetwork = local.client_subnet_self_link
    network_ip = local.client_ips[count.index]

    dynamic "access_config" {
      for_each = var.assign_client_external_ip ? [1] : []
      content {
        nat_ip = google_compute_address.client_external_address[count.index].address
      }
    }
  }

  # nic2 -> 1/2 server, SNIP and cluster backplane
  network_interface {
    subnetwork = local.server_subnet_self_link
    network_ip = local.server_ips[count.index]
  }

  allow_stopping_for_update = true

  # "Allow full access to all Cloud APIs" in the console. The cloud-platform
  # scope is the single scope that covers every API; the GCE default scope set
  # (devstorage.read_only, logging.write, monitoring.write, servicecontrol,
  # service.management.readonly, trace.append) has no compute access at all and
  # produces ACCESS_TOKEN_SCOPE_INSUFFICIENT rather than PERMISSION_DENIED,
  # which reads like an IAM problem and is not one.
  #
  # Scopes bound the token; IAM still decides what the identity may do. Leaving
  # email null uses the project's default compute service account, matching the
  # console default. Changing either needs a stop/start, which
  # allow_stopping_for_update above permits.
  service_account {
    email  = var.service_account_email != "" ? var.service_account_email : null
    scopes = ["cloud-platform"]
  }

  # The NSIPs are derived from the *_subnet_cidr_block variables rather than
  # from the subnets themselves, because provider endpoints must be resolvable
  # at plan time. When consuming existing networks that leaves room for the
  # declared CIDRs to drift from reality, so check them here instead of finding
  # out via an opaque "IP not in range" error from the GCP API.
  lifecycle {
    precondition {
      condition     = local.management_cidr == var.management_subnet_cidr_block
      error_message = "management_subnet_cidr_block is ${var.management_subnet_cidr_block} but subnet '${local.management_network_name}' is actually ${local.management_cidr}. Set the variable to match."
    }
    precondition {
      condition     = local.client_cidr == var.client_subnet_cidr_block
      error_message = "client_subnet_cidr_block is ${var.client_subnet_cidr_block} but subnet '${local.client_network_name}' is actually ${local.client_cidr}. Set the variable to match."
    }
    precondition {
      condition     = local.server_cidr == var.server_subnet_cidr_block
      error_message = "server_subnet_cidr_block is ${var.server_subnet_cidr_block} but subnet '${local.server_network_name}' is actually ${local.server_cidr}. Set the variable to match."
    }

    # The backplane used to be forbidden from sitting on 0/1, on the reasoning
    # that cluster steering over the management interface could cut Terraform
    # off from the NSIPs mid-apply. On GCP that reasoning is backwards, and the
    # rule cost two full apply cycles:
    #
    #   0/1 is the ONLY interface that has an IP address of its own. A VPX
    #   auto-configures its NSIP from nic0 and nothing else; 1/1 and 1/2 come up
    #   bare. A backplane with no address cannot carry a heartbeat, so a node
    #   given 1/2 joins and then sits at "(Adding)" forever.
    #
    # Addressing 1/2 after the fact does not work either -- see cluster.tf. So
    # the backplane belongs on 0/1 here, and this now only rejects an interface
    # that does not exist on a 3-NIC VPX.
    # node_count scaling checks. These are preconditions rather than variable
    # validations because each compares several variables against one another,
    # which variable validation could not do before Terraform 1.9; versions.tf
    # still only requires 1.5.
    precondition {
      condition     = length(var.nsips) == 0 || length(var.nsips) == var.node_count
      error_message = "nsips has ${length(var.nsips)} entries but node_count is ${var.node_count}. Give one NSIP per node, or leave the list empty to derive them from nsip_host_offset."
    }
    precondition {
      condition     = length(var.node_endpoints) == 0 || length(var.node_endpoints) == var.node_count
      error_message = "node_endpoints has ${length(var.node_endpoints)} entries but node_count is ${var.node_count}. Give one per node, or leave the list empty to derive them from the NSIPs."
    }

    # Priorities are base + node_id and the ADC accepts 0-31, so the usable
    # node_count depends on the base. At the old hardcoded base of 29 a fourth
    # node would have asked for priority 32 and been rejected mid-bootstrap.
    precondition {
      condition     = var.cluster_priority_base >= 0 && var.cluster_priority_base + var.node_count - 1 <= 31
      error_message = "cluster_priority_base ${var.cluster_priority_base} with node_count ${var.node_count} needs cluster priorities ${var.cluster_priority_base} to ${var.cluster_priority_base + var.node_count - 1}, but the ADC only accepts 0 to 31. Lower cluster_priority_base."
    }

    # The NSIPs grow with node_count, so a CLIP that sat safely below them at
    # three nodes can be swallowed at eight.
    precondition {
      condition     = !contains(local.nsips, local.clip)
      error_message = "The CLIP ${local.clip} collides with an NSIP. At node_count ${var.node_count} the NSIPs run ${local.nsips[0]} to ${local.nsips[var.node_count - 1]}. Move clip_host_offset (${var.clip_host_offset}) outside that range, or raise nsip_host_offset (${var.nsip_host_offset})."
    }

    precondition {
      condition     = contains(["0/1", "1/1", "1/2"], var.backplane_interface)
      error_message = "backplane_interface is ${var.backplane_interface}, which is not an interface on a 3-NIC GCP VPX. Valid values are 0/1 (management, the only NIC with an address), 1/1 (client) and 1/2 (server)."
    }
  }
}

# =============================================================================
# NITRO readiness probe -- optional, off by default.
#
# The fixed wait below is sized for the worst case: a VPX "regularly needs 6-10
# minutes", so adc_boot_wait is 600s and every apply pays all of it, including
# the ones where the appliance was answering at minute five.
#
# This probe polls each NSIP until NITRO actually responds, so the wait costs
# what the boot costs rather than the worst case. It sits BEFORE time_sleep
# rather than replacing it, which keeps the graph identical downstream:
#
#     instances + peering -> nitro_probe -> time_sleep.adc_boot -> resetters
#
# time_sleep.adc_boot keeps its address, so all 33 depends_on references in
# password_reset.tf and cluster.tf are untouched.
#
# It cannot make an apply fail that would otherwise have succeeded. On a
# timeout, or a host with no curl, it warns and falls through -- leaving the
# behaviour no worse than the fixed wait it replaced. count = 0 when
# adaptive_boot_wait is false, and a depends_on against a count = 0 resource is
# simply satisfied, exactly as the resetter pool in cluster.tf relies on.
#
# Requires curl on the Terraform host, and a route to the NSIPs -- which the
# password reset needs a moment later anyway, so this fails no earlier than
# that would have.
# =============================================================================

resource "terraform_data" "nitro_probe" {
  count = var.adaptive_boot_wait ? 1 : 0

  depends_on = [
    google_compute_instance.adc,
    google_compute_network_peering.mgmt_to_peer,
    google_compute_network_peering.peer_to_mgmt,
  ]

  # Same keying as time_sleep below: a new instance means a new probe.
  triggers_replace = join(",", google_compute_instance.adc[*].instance_id)

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    command     = <<-EOT
      set -u
      ips="${join(" ", local.nsips)}"
      cap=${var.adc_boot_probe_timeout}

      if ! command -v curl >/dev/null 2>&1; then
        echo "  !!  no curl on this host -- skipping probe, falling back to the full ${var.adc_boot_wait} wait"
        sleep ${trimsuffix(var.adc_boot_wait, "s")}
        exit 0
      fi

      start=$(date +%s)
      deadline=$((start + cap))

      for ip in $ips; do
        printf '  ..  waiting for NITRO on %s ' "$ip"
        while true; do
          # Any HTTP response means NITRO is listening. A 401 is a fine answer
          # here -- we are probing liveness, not authenticating.
          if curl -s -o /dev/null -m 5 "http://$ip/nitro/v1/config/nsversion" 2>/dev/null; then
            printf ' up after %ss\n' "$(( $(date +%s) - start ))"
            break
          fi
          if [ "$(date +%s)" -ge "$deadline" ]; then
            printf '\n  !!  probe timed out after %ss -- continuing anyway, the password reset will report the real error\n' "$cap"
            exit 0
          fi
          printf '.'
          sleep 10
        done
      done

      echo "  ok  all $(echo $ips | wc -w) node(s) answering NITRO after $(( $(date +%s) - start ))s"
    EOT
  }
}

# The ADC takes several minutes past instance creation before its management
# interface answers NITRO. Nothing in the GCP API reports that, so wait.
resource "time_sleep" "adc_boot" {
  # Peering is in here too: the route must exist before the first NITRO call,
  # and nothing else in the graph forces that ordering.
  depends_on = [
    google_compute_instance.adc,
    google_compute_network_peering.mgmt_to_peer,
    google_compute_network_peering.peer_to_mgmt,
    terraform_data.nitro_probe,
  ]

  # Without this the wait happens exactly once, ever. depends_on orders the
  # graph but does not force replacement, so rebuilding an instance later --
  # e.g. -replace to clear a half-formed cluster off a node -- would leave this
  # already satisfied in state and fire the first NITRO call at a node that is
  # still booting. Keying on the instance ids makes a new instance mean a new
  # wait.
  triggers = {
    instance_ids = join(",", google_compute_instance.adc[*].instance_id)
  }

  # With the probe on, NITRO has already answered by the time this runs, so all
  # that is left is a short settle. Without it, the original worst-case wait.
  create_duration = var.adaptive_boot_wait ? var.adc_boot_settle : var.adc_boot_wait
}
