# =============================================================================
# GCP project / placement
# =============================================================================

variable "project" {
  description = "GCP project in which to deploy resources"
  type        = string
}

variable "region" {
  description = "Region to deploy resources to"
  type        = string
}

variable "zone" {
  description = "Zone to deploy the ADC instances to. All three nodes are placed in the same zone so they share a subnet and can form an L2-style cluster."
  type        = string
}

variable "prefix" {
  description = "Name prefix applied to every created resource. Change this to run more than one deployment in the same project."
  type        = string
  default     = "adc-cluster"
}

# =============================================================================
# Instance
# =============================================================================

variable "node_count" {
  description = <<-EOT
    Number of ADC instances to build and form into a single cluster. This is
    the only thing you change to resize the deployment -- no .tf file needs
    editing at any node count.

    Everything derives from it: instances and their three NICs each, NSIPs,
    client and server addresses, external addresses, SNIPs, cluster priorities
    and the clusternode blocks.

    1 to 32. 32 is the NetScaler cluster limit, not a limit of this
    configuration. providers.tf and password_reset.tf each hold a fixed pool of
    32 blocks because citrixadc_password_resetter has no endpoint attribute and
    can only be aimed at a node through a provider alias, which Terraform
    cannot generate -- see local.max_nodes in locals.tf. Unused slots do
    nothing.

    node_count = 1 is allowed and gives a single-node cluster: a CCO with a
    CLIP and nothing to fail over to. Fine for testing the plumbing.

    Mind the practical limits before the appliance's: GCP vCPU quota
    (machine_type is per node), the management subnet's size, and
    cluster_priority_base + node_count - 1 staying at or below 31.

    Changing this on an existing deployment adds or removes instances and
    reconfigures the cluster in place. Removing nodes deletes them from the
    CLIP first, then destroys the VMs; the CCO (node 0) goes last.
  EOT
  type        = number
  default     = 3

  validation {
    condition     = var.node_count == floor(var.node_count)
    error_message = "node_count must be a whole number."
  }

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 32
    error_message = "node_count must be between 1 and 32. 32 is the NetScaler cluster limit."
  }
}

variable "machine_type" {
  description = "Instance type. Must allow for 3 NICs (GCP permits at most one NIC per vCPU), e.g. n1-standard-4."
  type        = string
  default     = "n1-standard-4"
}

variable "image" {
  description = "Image to use for the boot disk. Must be a NetScaler (Citrix) ADC image."
  type        = string
}

variable "public_ssh_key_file" {
  description = "Path to the public part of the SSH key with which to access the management interface. A leading ~ is expanded; it is resolved on the machine running Terraform, not your workstation."
  type        = string
}

variable "service_account_email" {
  description = "Service account attached to every ADC instance. Empty uses the project's default compute service account, which is what the console does. The scope is always cloud-platform (\"Allow full access to all Cloud APIs\") and is not configurable — see adc_instances.tf."
  type        = string
  default     = ""
}

variable "network_tags" {
  description = "Network tags applied to every ADC instance. Needed when the target networks carry firewall rules scoped with targetTags — an untagged instance matches none of them, and traffic is dropped with no RST, which looks exactly like a hung boot."
  type        = list(string)
  default     = []
}

# =============================================================================
# Networking
# =============================================================================

variable "use_existing_networks" {
  description = "Consume three VPC networks and subnets that already exist instead of creating them. Set this when the project is near the 50-network-per-project quota, or when you must deploy into a shared VPC. The three existing_* name variables become required."
  type        = bool
  default     = false
}

variable "existing_management_network" {
  description = "Name of the existing management VPC network. Only used when use_existing_networks is true."
  type        = string
  default     = ""
}

variable "existing_management_subnet" {
  description = "Name of the existing management subnet, in var.region. Only used when use_existing_networks is true."
  type        = string
  default     = ""
}

variable "existing_client_network" {
  description = "Name of the existing client VPC network. Only used when use_existing_networks is true."
  type        = string
  default     = ""
}

variable "existing_client_subnet" {
  description = "Name of the existing client subnet, in var.region. Only used when use_existing_networks is true."
  type        = string
  default     = ""
}

variable "existing_server_network" {
  description = "Name of the existing server VPC network. Only used when use_existing_networks is true."
  type        = string
  default     = ""
}

variable "existing_server_subnet" {
  description = "Name of the existing server subnet, in var.region. Only used when use_existing_networks is true."
  type        = string
  default     = ""
}

variable "peer_network" {
  description = "Name of an existing VPC network to peer the newly created management network with — set this to the network the Terraform host itself sits on, or Terraform will have no route to the NSIPs and the password reset will time out. Its CIDR must not overlap management_subnet_cidr_block. Ignored when use_existing_networks is true. Leave empty only if you run Terraform from inside the new management VPC."
  type        = string
  default     = ""
}

variable "create_firewall_rules" {
  description = "Create the management, client, server and backplane firewall rules. Set to false when deploying into shared networks that already permit what the cluster needs — allow rules are additive and affect every VM on the network."
  type        = bool
  default     = true
}

variable "management_subnet_cidr_block" {
  description = "CIDR block of the management subnet. The NSIPs and the CLIP are allocated out of this range. When use_existing_networks is true this must match the real subnet; a precondition enforces it."
  type        = string
}

variable "client_subnet_cidr_block" {
  description = "CIDR block for the client subnet."
  type        = string
}

variable "server_subnet_cidr_block" {
  description = "CIDR block for the server subnet. This subnet also carries cluster backplane traffic."
  type        = string
}

variable "controlling_subnet" {
  description = "CIDR block of the machines that will reach the NSIPs and the CLIP (i.e. where Terraform runs, plus your admin hosts)."
  type        = string
}

variable "assign_management_external_ip" {
  description = "Give every node an external IP on the management NIC. Terraform itself does not use these — it reaches the NSIPs privately over the peering. Defaults to false: a public NSIP exposes the NITRO API and SSH to the internet, guarded only by adc_admin_password."
  type        = bool
  default     = false
}

variable "assign_client_external_ip" {
  description = "Give every node its own external IP on the client NIC. A cluster VIP is striped across all nodes, so there is no single external address; front the nodes with a GCP load balancer if you need one entry point."
  type        = bool
  default     = true
}

# =============================================================================
# Addressing
#
# NSIPs and the CLIP are pinned to static private addresses so that the
# citrixadc provider endpoints are known at plan time. Leave the lists empty to
# have them derived from the management subnet CIDR.
# =============================================================================

variable "nsips" {
  description = "Explicit NSIPs, one per node in node_id order. Must lie inside management_subnet_cidr_block. Leave empty to derive from nsip_host_offset. The length is checked against node_count by a precondition in adc_instances.tf rather than here, because a variable validation block cannot see another variable before Terraform 1.9."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.nsips) == length(distinct(var.nsips))
    error_message = "nsips contains a duplicate address. Each node needs its own NSIP."
  }
}

variable "node_endpoints" {
  description = "Override the NITRO endpoints used for the per-node password reset, one per node in node_id order, e.g. [\"http://1.2.3.4\", ...]. Defaults to http://<nsip>. Values must be literals known at plan time — a provider endpoint cannot be computed. This does not help the cluster resource, which talks to the private-only CLIP. The length is checked against node_count by a precondition in adc_instances.tf."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.node_endpoints) == length(distinct(var.node_endpoints))
    error_message = "node_endpoints contains a duplicate. Each node needs its own endpoint."
  }
}

variable "nsip_host_offset" {
  description = "Host index of the first NSIP within the management subnet when nsips is not set. Nodes take offset, offset+1, offset+2."
  type        = number
  default     = 11
}

variable "clip" {
  description = "Cluster IP address. Must be a free address inside management_subnet_cidr_block. Leave empty to derive from clip_host_offset."
  type        = string
  default     = ""
}

variable "clip_host_offset" {
  description = "Host index of the CLIP within the management subnet when clip is not set."
  type        = number
  default     = 10
}

variable "data_host_offset" {
  description = "Host index of the first address used on the client and server subnets. Nodes take offset, offset+1, offset+2 on each."
  type        = number
  default     = 11
}

variable "create_clip_alias" {
  description = "Attach the CLIP to the CCO node's management NIC as a GCP alias IP range. GCP only delivers traffic to addresses it knows about, so without this the CLIP is unreachable from elsewhere in the VPC. See the caveat in the report: the alias is pinned to node 0 and does not follow a CCO failover."
  type        = bool
  default     = true
}

# =============================================================================
# Cluster
# =============================================================================

variable "cluster_id" {
  description = "Cluster ID"
  type        = number
  default     = 1
}

variable "cluster_tunnel_mode" {
  description = <<-EOT
    Steering tunnel mode for the cluster nodes.

    Defaults to UDP. GCP's fabric drops frames carrying foreign MAC addresses,
    so plain L2 steering (NONE) cannot forward traffic between nodes in cloud,
    whatever it does on-prem -- which is why the cluster_3node reference uses
    NONE and this does not.

    Recorded for context: with UDP, node 0 bootstrapped correctly but nodes 1
    and 2 stalled at "(Adding)" with health UNKNOWN while the CCO reported
    "Heartbeats are not seen on backplane". That may or may not be related to
    the tunnel mode. GRE is the other cloud-appropriate option and the server
    firewall already permits IP protocol 47 for it.
  EOT
  type        = string
  default     = "UDP"

  validation {
    condition     = contains(["NONE", "GRE", "UDP"], var.cluster_tunnel_mode)
    error_message = "cluster_tunnel_mode must be one of NONE, GRE or UDP."
  }
}

variable "management_interface" {
  description = "The ADC interface carrying the NSIP. On GCP the first attached NIC is always the management interface and is presented inside the ADC as 0/1, so this is descriptive rather than something you can move — the NIC order in adc_instances.tf is what actually decides it. It is also, by default, the cluster backplane: it is the only interface the ADC gives an address to on its own."
  type        = string
  default     = "0/1"
}

variable "backplane_interface" {
  description = <<-EOT
    Interface used as the cluster backplane, without the node-id prefix. On a
    3-NIC VPX 0/1 is management, 1/1 is the client NIC and 1/2 is the server
    NIC. The node id is prepended per node, so "0/1" yields 0/0/1, 1/0/1,
    2/0/1.

    Leave this at 0/1, the management interface. On-prem the backplane belongs
    on a dedicated NIC, and the cluster_3node reference accordingly uses 1/1 --
    but in GCP 0/1 is the only interface that has an address at all. A VPX
    auto-configures its NSIP from nic0 and nothing else, so 1/1 and 1/2 come up
    bare, and a backplane with no address cannot source a heartbeat. Pointing
    the backplane at 1/2 produced exactly that: node 0 bootstrapped, node 1
    joined, and the apply then spent 30 minutes waiting for it to leave
    "(Adding)" before failing with a bare timeout.

    Addressing 1/2 afterwards does not rescue it, because the cluster resource
    blocks on the node going ACTIVE before any later resource can run -- the
    SNIP that would fix the node cannot be applied until the node is fixed. See
    the comment in cluster.tf.

    If you ever do move this to a data NIC -- on real L2, or once something
    addresses the interface pre-join -- open that subnet to intra-subnet
    traffic first. The client rule permits only TCP 80 and 443 and would drop
    every heartbeat without a word.
  EOT
  type        = string
  default     = "0/1"
}

variable "cluster_priority_base" {
  description = <<-EOT
    Cluster priority assigned to node 0. Every other node gets base + its node
    id, so the lowest value -- node 0 -- wins the CCO election and the order is
    stable as nodes are added.

    The ADC accepts 0 to 31 and base + node_count - 1 has to fit inside that; a
    precondition in adc_instances.tf checks it. The base was hardcoded at 29
    when this only ever built three nodes, which happened to work and would
    have put a fourth node on priority 32.

    If you are updating a cluster that was built at the old 29 base and want to
    avoid a one-off "set cluster node -priority" on each node, set this to 29 --
    but that caps you at three nodes.
  EOT
  type        = number
  default     = 1
}

variable "hello_interval" {
  description = "Cluster hello interval in milliseconds"
  type        = number
  default     = 200
}

variable "configure_server_snips" {
  description = <<-EOT
    Configure each node's server-NIC address (nic2) as a spotted SNIP on the
    CLIP once the cluster has formed.

    This is a data-plane setting, not a clustering one. GCP assigns an address
    to each instance's nic2 but the ADC never sees it, so interface 1/2 comes up
    with no IP and the node cannot reach a back-end server. These SNIPs are what
    give it one.

    It used to be the fix for the backplane as well. It is not, and cannot be:
    the cluster resource blocks until every node reports ACTIVE, so nothing in
    snips.tf runs until the cluster is already healthy. The backplane is on 0/1
    for that reason -- see var.backplane_interface.
  EOT
  type        = bool
  default     = true
}

variable "configure_client_snips" {
  description = <<-EOT
    Configure each node's client-NIC address as a spotted SNIP on the CLIP after
    the cluster forms.

    Not needed to form the cluster, and not needed if you only ever manage the
    appliance. Needed for traffic: without it interface 1/1 has no IP and the
    data plane cannot originate or answer anything.
  EOT
  type        = bool
  default     = true
}

variable "save_cluster_config" {
  description = <<-EOT
    Save the running configuration on the CLIP once the cluster is formed, which
    writes ns.conf on every node.

    Without it the cluster exists only in the running config, and any node that
    reboots -- including during a CCO failover -- comes back without its
    backplane address and drops out of the cluster.
  EOT
  type        = bool
  default     = true
}

variable "cluster_endpoint" {
  description = "Override for the NITRO endpoint the cluster resource talks to. Defaults to http://<clip>. Only set this if you reach the CLIP through some other address."
  type        = string
  default     = ""
}

# =============================================================================
# Credentials
# =============================================================================

variable "adc_admin_username" {
  description = "Admin username for all nodes"
  type        = string
  default     = "nsroot"
}

variable "adc_admin_password" {
  description = <<-EOT
    Password to set on every node, and to use for all NITRO calls afterwards.
    On GCP the ADC boots with its password set to the GCP instance id; this
    configuration resets it to this value before forming the cluster.

    One value covers the whole deployment. All 32 provider aliases, all 32
    password resetters, citrixadc_cluster and the cluster watcher read this
    same variable -- there is no per-node password anywhere.

    Deliberately has NO default and is NOT set in terraform.tfvars, so
    Terraform asks for it once per command. To be asked only once for a whole
    deployment, save the plan and apply that:

        terraform plan -out=tfplan      # prompts
        terraform apply tfplan          # reuses it

    The plan file embeds the password, so delete it afterwards and keep it out
    of git. For unattended runs, export TF_VAR_adc_admin_password instead and
    no prompt appears.

    Be aware of what prompting does not buy you: Terraform does not mask the
    input as you type it, and the value lands in terraform.tfstate in plaintext
    regardless -- sensitive = true only masks CLI output. Prompting keeps the
    password out of the config FILE, which is the thing that gets committed by
    accident.
  EOT
  type        = string
  sensitive   = true

  # An empty password is accepted by Terraform but is fatal, and fails in the
  # most misleading way available. NITRO answers "Password is not specified"
  # with a non-200; the cluster resource's bootstrap poll treats every non-200
  # as "not reachable yet" and keeps retrying until its budget expires. The run
  # then fails with "timeout waiting for cluster operation to complete" and no
  # indication that credentials were ever involved. Raising the timeout or
  # fixing the network changes nothing, because neither is the problem.
  #
  # Easy to hit by pressing Enter at the interactive prompt -- which, now that
  # the prompt is the normal path rather than the discouraged one, makes this
  # validation load-bearing rather than a formality. Do not remove it.
  validation {
    condition     = length(var.adc_admin_password) > 0
    error_message = "adc_admin_password must not be empty. Type it at the prompt, or set it with: export TF_VAR_adc_admin_password='...'"
  }

  # Typing at a prompt is exactly where a stray leading or trailing space gets
  # in, and it is invisible when you re-type it to compare. The resetter would
  # set the padded password, every later NITRO call would send the same padded
  # value and appear to work -- until something sends the trimmed one, and the
  # failure arrives as yet another unexplained auth timeout. Reject it here
  # instead.
  validation {
    condition     = var.adc_admin_password == trimspace(var.adc_admin_password)
    error_message = "adc_admin_password has leading or trailing whitespace. That is almost always an accident of typing or pasting it; remove it."
  }
}

# =============================================================================
# Sequencing
# =============================================================================

variable "enable_password_reset" {
  description = "Reset each node's password from the GCP instance id to adc_admin_password before forming the cluster. Turn off only if the nodes already carry adc_admin_password."
  type        = bool
  default     = true
}

variable "adc_boot_wait" {
  description = "How long to wait after the instances are created before issuing the first NITRO call. A VPX regularly needs 6-10 minutes to bring up its management interface, and nothing in the GCP API reports when it has. Too short and the password reset fails on an i/o timeout that looks like a network fault. Ignored when adaptive_boot_wait is true, except as the fallback when the Terraform host has no curl."
  type        = string
  default     = "600s"
}

variable "adaptive_boot_wait" {
  description = <<-EOT
    Poll each NSIP until NITRO answers instead of sleeping the full
    adc_boot_wait, then wait only adc_boot_settle on top.

    adc_boot_wait is sized for the worst case, so every apply pays 10 minutes
    even when the appliance was ready at minute five. This spends what the boot
    actually costs. Typical saving is 3-5 minutes per apply.

    Off by default, because the fixed wait is known-good and the trade is real:
    "NITRO answers" is a slightly earlier moment than "NITRO will accept a
    password change", and adc_boot_settle is what covers the gap. 300s was
    already found to be too short once.

    The probe never hard-fails -- on timeout, or on a host with no curl, it
    warns and falls through -- so enabling this cannot break an apply that
    would otherwise have worked. Requires curl on the Terraform host.
  EOT
  type        = bool
  default     = false
}

variable "adc_boot_settle" {
  description = "Wait applied after the NITRO probe succeeds, covering the gap between the appliance answering NITRO and being ready to accept a password change. Only used when adaptive_boot_wait is true. Raise it if the password reset fails with the probe on but succeeds with it off."
  type        = string
  default     = "90s"
}

variable "adc_boot_probe_timeout" {
  description = "Seconds the NITRO probe will wait for any single node before giving up and letting the apply continue. Defaults to 900, half again the 600s fixed wait, so a genuinely slow boot still gets picked up rather than cut short. Only used when adaptive_boot_wait is true."
  type        = number
  default     = 900
}

# =============================================================================
# Progress reporting
# =============================================================================

variable "progress_logs" {
  description = <<-EOT
    Print a timestamped milestone line as each phase of the apply completes:
    instances created, NITRO reachable, passwords reset, cluster formed, SNIPs
    configured, config saved.

    Purely additive. The markers depend on the real resources, nothing depends
    on them, and they create no infrastructure -- they cannot affect what is
    built or in what order.

    Each marker re-runs on every apply, so progress.tf shows six trivial
    resource changes in every plan. Set this to false to silence them.
  EOT
  type        = bool
  default     = true
}

variable "cluster_watch_logs" {
  description = <<-EOT
    Report cluster node state while citrixadc_cluster.this is forming.

    That resource blocks for 10-15 minutes printing only "Still creating...".
    The watcher polls node 0 over NITRO and prints each transition -- node
    declared, node rebooting, node ACTIVE -- so a run that is stuck at
    "(Adding)" is visible within a minute instead of at the 30m timeout.

    It is scheduled alongside the cluster resource, not after it, because it
    shares the cluster's dependencies and nothing depends on it. Read-only, and
    every failure path exits 0, so it cannot affect the apply.

    Requires curl on the Terraform host and a route to the NSIPs.
  EOT
  type        = bool
  default     = true
}

variable "cluster_watch_interval" {
  description = "Seconds between cluster-state polls. Only used when cluster_watch_logs is true. Output is printed on change only, so a short interval does not make the log noisier -- it just catches transitions sooner."
  type        = number
  default     = 20
}

variable "cluster_watch_timeout" {
  description = "Seconds the watcher keeps polling before giving up. Only used when cluster_watch_logs is true. Defaults to 2400 (40 min), comfortably past the cluster resource's own 30m budget, so the watcher never goes quiet while the thing it is watching is still running. Giving up is cosmetic; it does not stop or fail the apply."
  type        = number
  default     = 2400
}
