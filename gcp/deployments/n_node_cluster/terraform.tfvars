# Copy to terraform.tfvars and adjust. Do not commit the real file.
#
# Configured to CREATE three new VPC networks, with addressing in 172.20.x so
# nothing can collide with the crowded 10.0.x space this project uses.
#
# ---------------------------------------------------------------------------
# BEFORE YOU APPLY
#
# NETWORK QUOTA. This creates 3 VPCs against a 50-per-project limit. Check
# there is room, or the apply dies at the very first resource:
#     gcloud compute networks list | wc -l
#
# STATE. terraform.tfstate lives next to this file and is the only record of
# what was built. If you sync this directory from another machine, copy the
# state out first -- overwriting it strands every resource in GCP and the next
# apply fails with "Error 409: ... alreadyExists" on all of them.
#
# Resolved and no longer a concern: tej-freebsd-114 boots fine, and the
# firewall rules in network.tf already permit everything the cluster needs.
# ---------------------------------------------------------------------------

# ---------- GCP ----------
# Leave nothing templated here. A literal placeholder in this field once got
# as far as a SERVICE_DISABLED error against a project named "my-gcp-project".
#   terraform.tfvars is NOT the same file as terraform.tfvars.example --
#   Terraform never auto-loads the .example one.
project = "cluster-gcp"
region  = "us-east1"
zone    = "us-east1-b"
prefix  = "adc-cluster"

# ---------- Instance ----------
# THE ONLY KNOB FOR CLUSTER SIZE. Everything derives from this: instances,
# addresses, SNIPs, cluster priorities, firewall scope, clusternode blocks.
# No .tf file needs editing at any size.
#
# 1 to 32 -- 32 being the NetScaler cluster limit, not a limit of these
# scripts. What will actually stop you first:
#   - GCP vCPU quota. machine_type below is per node, so 8 nodes of
#     n2d-standard-8 is 64 vCPUs in us-east1.
#   - cluster_priority_base + node_count - 1 must stay at or below 31.
#   - the management subnet must have room for the CLIP plus one NSIP per node.
# All three are checked at plan time rather than part-way through an apply.
#
# Changing this on a live deployment adds or removes nodes in place. Growing is
# cheap; shrinking removes the node from the CLIP before destroying the VM.
#
# At node_count = 32 you are using the ADC's entire priority range, so
# cluster_priority_base MUST be 0 (priorities 0..31). Any higher base overflows
# 31 and the precondition in adc_instances.tf rejects the plan.
node_count = 1

# Must allow 3 NICs: GCP permits at most one NIC per vCPU. This is per node and
# does not change with node_count.
machine_type = "n2d-standard-8"

image = "https://www.googleapis.com/compute/v1/projects/cluster-gcp/global/images/ns-zion-73-46"

# Resolved on the machine running Terraform. A leading ~ is expanded.
public_ssh_key_file = "~/.ssh/id_rsa.pub"

# Only needed if the target networks use tag-scoped firewall rules. New
# networks created here use untagged rules, so this stays empty.
network_tags = []

# IP forwarding and the cloud-platform API scope are always on and are NOT
# tfvars settings -- they are hardcoded in adc_instances.tf because the cluster
# cannot work without them:
#   can_ip_forward = true                 "Enable IP forwarding"
#   scopes         = ["cloud-platform"]   "Allow full access to all Cloud APIs"
# Verify after apply with:  terraform output instance_settings
# Only the identity is adjustable; empty means the default compute SA.
service_account_email = ""

# ---------- Networks ----------
# Create all three. Each NIC of a VM must be on a different network, so this
# deployment always needs exactly three.
use_existing_networks = false

# 172.20.x deliberately: must not overlap the peer network below, and must not
# collide with the 10.0.x / 10.10.x / 10.20.x / 10.50.x ranges already in use.
management_subnet_cidr_block = "172.20.1.0/24"
client_subnet_cidr_block     = "172.20.2.0/24"
server_subnet_cidr_block     = "172.20.3.0/24"

# THE ONE THAT MATTERS. A new VPC is isolated -- without this, Terraform has no
# route to the NSIPs and the apply fails at the password reset after building
# everything. Set it to the network the Terraform host is on.
#   gcloud compute instances describe <this-vm> --zone=us-east1-b \
#     --format="value(networkInterfaces[].network.basename())"
peer_network = "jaz-n1-mgmt"

# CIDR of the subnet the Terraform host sits in, on the far side of the
# peering. The management firewall opens NITRO and SSH to this range.
controlling_subnet = "10.0.1.0/24"

# Required for new networks: they permit no ingress until these exist.
create_firewall_rules = true

# ---------- Addressing ----------
# Left to derive from the CIDRs above, since a fresh VPC has nothing in it.
# Each list grows with node_count; at node_count = 3 that is:
#   clip   172.20.1.10        (clip_host_offset = 10)
#   nsips  172.20.1.11/12/13  (nsip_host_offset = 11, then +1 per node)
#   client 172.20.2.11/12/13  (data_host_offset = 11, then +1 per node)
#   server 172.20.3.11/12/13
# At node_count = 8 the NSIPs would run .11 to .18. A precondition rejects a
# clip_host_offset that ends up inside that range.
# Set nsips/clip explicitly only to pin them -- if you do, nsips must have
# exactly node_count entries.
nsips = []
clip  = ""

create_clip_alias = true

# ---------- External addresses ----------
# Management stays private: a public NSIP exposes NITRO and SSH to the whole
# internet behind nothing but adc_admin_password. Reach the nodes over the
# peering instead.
assign_management_external_ip = false
assign_client_external_ip     = true

# ---------- Cluster ----------

cluster_id = 1

# Node 0 gets this, node 1 gets base+1, and so on; lowest wins the CCO
# election. Must leave base + node_count - 1 at or below 31, which the ADC
# enforces and a precondition catches first.
#
# This was hardcoded at 29 for the original three-node build. If you are
# updating that cluster in place and would rather not see a one-off
# "set cluster node -priority" against each node, put 29 back -- at the cost of
# never getting past three nodes.
#
# 0, not 1, because node_count is 32. The ADC accepts priorities 0 to 31
# inclusive (NetScaler docs: "Default value: 31 Minimum value: 0 Maximum
# value: 31"), so a 32-node cluster needs the whole range and base 0 is the
# only value that fits. Priority 0 is not special -- lower simply wins the CCO
# election, so node 0 still leads. At base 1 the plan is rejected before
# anything is built, which is the failure you hit.
#
# Max node_count for a given base is 32 - base.
cluster_priority_base = 0

# GCP's fabric drops frames with foreign MACs, so plain L2 steering (NONE) does
# not work in cloud, whatever it does on-prem. The cluster_3node reference uses
# NONE because it runs on real L2.
cluster_tunnel_mode = "UDP"

# 0/1 management, 1/1 client, 1/2 server.
#
# THE BACKPLANE GOES ON 0/1. This is the opposite of on-prem practice and of
# the cluster_3node reference, and getting it wrong costs half an hour per
# attempt. A VPX auto-configures its NSIP from nic0 and nothing else, so 0/1 is
# the only interface with an address; 1/1 and 1/2 come up bare. A backplane
# with no address cannot carry a heartbeat, the joining node never leaves
# "(Adding)", and the apply fails with "timeout waiting for cluster operation
# to complete" and no further explanation.
#
# Adding the address later does not help -- citrixadc_cluster blocks until
# every node is ACTIVE, so the fix can never be applied before the thing
# waiting for it gives up. See cluster.tf.
#
# Heartbeats and UDP steering on 0/1 need the management subnet open to itself,
# which the management-backplane firewall rule in network.tf provides.
management_interface = "0/1"
backplane_interface  = "0/1"
hello_interval       = 200

# ---------- SNIPs ----------
# Data plane only. None of these are needed to form the cluster -- that is what
# the backplane note above is for.
#
#   configure_server_snips nic2 address -> spotted SNIP on the CLIP, so the
#                          nodes can reach back-end servers.
#   configure_client_snips nic1 address -> spotted SNIP, so the nodes can
#                          originate and answer client-side traffic.
#   save_cluster_config    write ns.conf on every node at the end, so a reboot
#                          does not undo all of it.
#
# Both SNIP sets are citrixadc_nsip resources applied on the CLIP after the
# cluster forms. The clusternode addsnip option looks like a neater way to do
# it and is not: it cannot set ownernode, so the ADC rejects the SNIP with
# errorcode 476 "Owner node is not specified" and the apply dies mid-bootstrap.
# Do not re-enable it.
configure_server_snips = true
configure_client_snips = true
save_cluster_config    = true

# ---------- Credentials ----------
adc_admin_username = "nsroot"

# adc_admin_password is deliberately NOT set here.
#
# The variable has no default, so Terraform asks for it once per command and
# that single value is used for every node -- all 32 provider aliases, all 32
# password resetters, the cluster resource and the watcher read the same
# var.adc_admin_password. There is no per-node password anywhere in this
# configuration.
#
# To be asked only once for a whole deployment, save the plan:
#
#     terraform plan -out=tfplan     <- prompts here
#     terraform apply tfplan         <- reuses it, no second prompt
#
# (tfplan embeds the password. Delete it after applying, and keep it out of
# git.) For unattended runs, export TF_VAR_adc_admin_password instead and no
# prompt appears at all.
#
# Two things the prompt does NOT do: it is not masked as you type, and it does
# not keep the password out of terraform.tfstate -- that is plaintext either
# way. What it does do is keep the password out of this file.
#
# Do not be tempted to press Enter at the prompt. An empty password surfaces
# half an hour later as "timeout waiting for cluster operation to complete"
# with nothing pointing at credentials; a validation in variables.tf rejects it
# up front, and that validation is now load-bearing rather than a formality.
# adc_admin_password = "..."

# ---------- Sequencing ----------
enable_password_reset = true

# A VPX regularly needs 6-10 minutes before NITRO answers. 300s was too short.
# Only the fallback now -- adaptive_boot_wait below replaces it in normal runs.
adc_boot_wait = "600s"

# Poll the NSIPs until NITRO actually answers instead of always sleeping the
# full 600s above, then wait adc_boot_settle on top. This is what stops every
# apply paying the worst case. Expect the wait to drop to roughly
# (real boot time + 90s).
adaptive_boot_wait = true
adc_boot_settle    = "90s"

# Seconds the probe waits on one node before giving up and continuing. It never
# fails the apply -- on timeout it warns and falls through to the password
# reset, which reports the real error.
adc_boot_probe_timeout = 900

# ---------- Progress logging ----------
progress_logs = true

# Report node state while the cluster forms, instead of 15 min of
# "Still creating...". Read-only, runs alongside the cluster resource.
#
# Raised from 2400 (40 min) for the 32-node build. Nodes join SEQUENTIALLY and
# each one reboots, so formation scales with node_count: at 32 nodes the
# cluster resource can legitimately run for two to three hours. A 40-minute
# watcher would stop reporting in the first fifth of the run and leave you
# staring at "Still creating..." for the rest -- exactly what it exists to
# prevent. 14400 is 4 hours. Giving up is cosmetic and never fails the apply.
cluster_watch_logs     = true
cluster_watch_interval = 20
cluster_watch_timeout  = 14400
