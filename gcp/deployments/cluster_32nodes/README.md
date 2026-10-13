# NetScaler ADC Cluster on GCP

Terraform configuration that builds an *n*-node NetScaler (Citrix) ADC cluster on Google Cloud
Platform, end to end: VPC networks, three-NIC VPX instances, the initial password reset, cluster
formation, data-plane SNIPs and a config save.

Unlike the sibling `cluster_3node/` and `standalone_3nic/` folders, this one is self-contained — it
creates (or consumes) its own networks and forms the cluster in a single `terraform apply`.

## What it builds

| Resource | Detail |
|---|---|
| 3 VPC networks + subnets | management, client, server. GCP forbids two NICs of one instance on the same network, so three are always needed. Created, or looked up when `use_existing_networks = true`. |
| Firewall rules | management (admin/Terraform ingress), management-backplane (permissive, scoped to the management CIDR), client (80/443 from anywhere), server, and a GRE rule for `cluster_tunnel_mode = "GRE"`. |
| VPC peering | management ↔ `peer_network`, so the Terraform host has a route to the NSIPs. |
| *n* ADC instances | 3 NICs each, `can_ip_forward = true`, `cloud-platform` API scope, static NSIPs. |
| Password reset | each node's nsroot password goes from the GCP instance id to `adc_admin_password`. |
| Cluster | node 0 bootstrapped as CCO, CLIP created, remaining nodes declared and joined. |
| Spotted SNIPs | per-node client (1/1) and server (1/2) addresses, with `ownernode` set. |
| Config save | one `save` on the CLIP writes `ns.conf` on every node. |

Addressing, with the default offsets and a `172.20.x` layout:

```
CLIP     172.20.1.10            clip_host_offset = 10
NSIPs    172.20.1.11, .12, …    nsip_host_offset = 11   nic0 -> ADC 0/1  management + backplane
client   172.20.2.11, .12, …    data_host_offset = 11   nic1 -> ADC 1/1  VIP
server   172.20.3.11, .12, …                            nic2 -> ADC 1/2  SNIP
```

## Files

| File | Contents |
|---|---|
| `versions.tf` | Terraform ≥ 1.5.0, `citrix/citrixadc` ≥ 2.2.2 (see the comment — both floors are load-bearing). |
| `providers.tf` | The cluster-wide provider (endpoint = CLIP) plus 32 per-node aliases. |
| `variables.tf` | Every input, each with the reasoning behind its default. |
| `locals.tf` | Network/subnet resolution, address derivation, the `cluster_nodes` list. |
| `network.tf` | Networks, subnets, firewall rules, external addresses, two `check` blocks. |
| `peering.tf` | Bidirectional peering to `peer_network`. |
| `adc_instances.tf` | The VPX instances, their NIC order, the optional NITRO readiness probe, the boot wait, and all scaling preconditions. |
| `password_reset.tf` | 32 `citrixadc_password_resetter` blocks, `count`-gated by `node_count`. |
| `cluster.tf` | The single `citrixadc_cluster` resource and its poll timeouts. |
| `snips.tf` | Spotted SNIPs and `citrixadc_nsconfig_save`. |
| `progress.tf` | Six inert markers that print a timestamped line as each phase of the apply completes. |
| `cluster_watch.tf` | Read-only NITRO poller that reports node state *while* the cluster is forming. |
| `outputs.tf` | Topology, addresses, and ready-made verification commands. |
| `terraform.tfvars.example` | Annotated starting point. Copy to `terraform.tfvars`. |

Three HTML companions sit alongside these — open them in a browser:

- **`GUIDE.html`** — how to modify the scripts: resizing, the settings you will actually change,
  what not to touch, recipes, troubleshooting, teardown.
- **`ISSUES.html`** — the failures encountered building this, phase by phase, and their fixes.
  Read this before debugging an apply of your own.
- **`REPORT.html`** — per-file script reference.

## Prerequisites

- Terraform ≥ 1.5.0 and credentials for the target GCP project (`gcloud auth application-default login`).
- A NetScaler ADC image in the project. **Validate it standalone first** — boot one throwaway VM from
  it and confirm port 22 answers within ~10 minutes. A bad image costs a full apply cycle.
- Spare network quota. This creates 3 VPCs against a 50-per-project limit:
  `gcloud compute networks list | wc -l`. Or set `use_existing_networks = true`.
- vCPU quota for `node_count × machine_type`, and a machine type with at least 3 vCPUs (GCP permits
  one NIC per vCPU).
- A route from the Terraform host to the NSIPs — see below.
- A POSIX shell on the Terraform host, if `progress_logs`, `cluster_watch_logs` or
  `adaptive_boot_wait` is on — all three run `local-exec` through `/bin/sh`. `curl` is wanted too, but
  a missing `curl` is handled inside the scripts; a missing `/bin/sh` is not, because a provisioner
  that cannot start fails the apply. Set all three to `false` when running Terraform from Windows.

## Quick start

```bash
cp terraform.tfvars.example terraform.tfvars
# edit: project, region, zone, image, peer_network, controlling_subnet, public_ssh_key_file

terraform init
terraform plan -out=tfplan     # asks for the ADC password here
terraform apply tfplan         # reuses it — no second prompt
rm -f tfplan                   # the plan file embeds the password
```

`adc_admin_password` has no default and is not set in `terraform.tfvars`, so Terraform asks for it.
One answer covers the whole deployment — see [The admin password](#the-admin-password).

Budget 30–45 minutes. Most of it is the `adc_boot_wait` (10 min default) plus the reboot each node
takes when it joins the cluster. Set `adaptive_boot_wait = true` to spend what the boot actually
costs instead of the worst case — typically 3–5 minutes back per apply.

## The admin password

`adc_admin_password` is **not** written in `terraform.tfvars`. The variable has no default, so
Terraform asks for it, and that one answer is used everywhere: all 32 provider aliases, all 32
password resetters, the cluster resource and the watcher read the same variable. There is no
per-node password in this configuration — nothing to keep in sync.

Three ways to supply it, all the same variable:

| How | When to use it | Prompts? |
|---|---|---|
| `terraform plan -out=tfplan` then `terraform apply tfplan` | Normal use. The saved plan carries the value. | Once per deployment |
| `terraform plan` then `terraform apply` | Quick iterations. | Once **per command** — and you must type it identically each time |
| `export TF_VAR_adc_admin_password='...'` | CI, or repeated runs in one shell. | Never |

Be clear about what prompting does and does not buy you:

- **It does** keep the password out of the config file — the thing that gets committed by accident.
- **It does not** mask your typing. Terraform echoes interactive variable input in plaintext even
  for a `sensitive` variable.
- **It does not** keep the password out of `terraform.tfstate`, which is plaintext regardless.
  `sensitive = true` only masks CLI output.

Two failure modes the validations now catch up front, both of them specific to typing at a prompt:

- **An empty password.** Pressing Enter gets you a 30-minute apply that dies on `timeout waiting
  for cluster operation to complete`, naming nothing to do with credentials. See *Things that are
  deliberate*.
- **Leading or trailing whitespace.** Invisible when you re-type it to compare, and it produces an
  auth failure that arrives much later than the typo did.

> **`terraform destroy` prompts too.** Teardown removes nodes from the CLIP before destroying the
> VMs, so it needs working credentials. Answer it with the password the nodes actually have — a
> different answer there fails the destroy partway through, with the cluster half dismantled.

## Watching an apply

Two phases of the run — the boot wait and the cluster formation — are long and silent by default.
Terraform prints `Still creating...` and nothing else for 10–15 minutes at a stretch. Two optional,
inert features fix that, both on by default:

- **`progress.tf`** prints a timestamped milestone as each phase completes:

  ```
  ==  [09:14:22Z]  3/6  PASSWORDS RESET  --  3 node(s)
        next: forming the cluster. This is the long one -- node 0 bootstraps as
        CCO, then each node joins and REBOOTS. Expect 10-15 min of silence.
  ```

- **`cluster_watch.tf`** polls node 0 over NITRO *while* `citrixadc_cluster` is still blocking, and
  prints each transition, so a node stuck at `(Adding)` shows up within a minute instead of at the
  30-minute timeout:

  ```
  ~~  [09:21:40Z +412s]  node0=ACTIVE/UP  node1=(Adding)/NOT_UP  node2=(Adding)/NOT_UP
  ```

Both are read-only, create no infrastructure, and nothing in the graph depends on them — they
cannot change what is built or in what order, and every failure path in the watcher exits 0. The
watcher shares the cluster resource's dependencies rather than depending on the cluster, so
Terraform schedules it *alongside* the thing it reports on. The markers re-run on every apply by
design, which is why `progress.tf` shows six trivial changes in every plan; set `progress_logs =
false` to silence them.

The one case where they are not free is a host with no `/bin/sh` — see *Prerequisites*.

Then verify from a host on the management network:

```bash
terraform output verify_cluster     # prints the exact commands
ssh nsroot@<clip>
  show cluster instance 1
  show cluster node
  show ns ip
```

Every node must read **health UP**. A node showing `(Adding)` or `UNKNOWN` has not really joined, and
neither has `There are no spotted SNIPs configured` or `Heartbeats are not seen on backplane` been
resolved.

## Reachability — the thing that fails applies

Terraform talks NITRO to each node's NSIP (password reset) and to the CLIP (cluster formation). Both
are private addresses. A freshly created VPC is isolated, so by default the Terraform host has **no
route to either**, and the apply builds every instance and then dies on an i/o timeout that names
nothing useful.

Pick one:

- Set `peer_network` to the network the Terraform host sits on (and `controlling_subnet` to its
  subnet CIDR). The CIDRs must not overlap — that is why the defaults live in `172.20.x`.
- Run Terraform from inside the new management VPC.
- Use `use_existing_networks = true` against networks that are already routable.

`node_endpoints` can redirect the *password reset* elsewhere, but it does not help the cluster
resource: the CLIP is private-only and has no external counterpart.

A `check` block in `network.tf` warns at plan time when none of these is configured.

## Sizing

`node_count` is the only knob. 1 to 32 — 32 is the NetScaler cluster limit, not a limit of this
configuration, and no `.tf` file needs editing at any size. Instances, NICs, addresses, external
addresses, SNIPs, cluster priorities and `clusternode` blocks all derive from it.

`providers.tf` and `password_reset.tf` carry a fixed pool of 32 blocks because
`citrixadc_password_resetter` has no endpoint attribute — a provider alias is the only way to aim it
at a node, and Terraform can neither interpolate `provider =` nor put `count` on a provider block.
Slots at or above `node_count` are counted out, pointed at loopback, and never dialled. **Don't edit
either file.**

You hit these before you hit 32: GCP vCPU quota, the size of the management subnet, and
`cluster_priority_base + node_count - 1 ≤ 31`. Preconditions in `adc_instances.tf` catch the last one,
plus CLIP/NSIP collisions and list-length mismatches.

## Key variables

Required, no default: `project`, `region`, `zone`, `image`, `public_ssh_key_file`,
`management_subnet_cidr_block`, `client_subnet_cidr_block`, `server_subnet_cidr_block`,
`controlling_subnet`, `adc_admin_password`.

Most-adjusted of the rest:

| Variable | Default | Notes |
|---|---|---|
| `node_count` | `3` | Cluster size, 1–32. |
| `machine_type` | `n1-standard-4` | Per node; needs ≥ 3 vCPUs. |
| `prefix` | `adc-cluster` | Change it to run two deployments in one project. |
| `peer_network` | `""` | See *Reachability*. |
| `use_existing_networks` | `false` | Makes the six `existing_*` name variables required. |
| `cluster_tunnel_mode` | `UDP` | `NONE` (plain L2) cannot work on GCP — the fabric drops foreign MACs. `GRE` is the other cloud option; the firewall already permits IP protocol 47. |
| `backplane_interface` | `0/1` | Leave it. See below. |
| `cluster_priority_base` | `1` | Node 0 gets this; lowest wins the CCO election. |
| `adc_boot_wait` | `600s` | A VPX regularly needs 6–10 minutes before NITRO answers. Ignored when `adaptive_boot_wait` is on, except as the no-`curl` fallback. |
| `adaptive_boot_wait` | `false` | Poll each NSIP until NITRO answers instead of sleeping the full `adc_boot_wait`, then wait only `adc_boot_settle` (`90s`) on top. Off by default because the fixed wait is known-good; the probe itself can never fail an apply. |
| `progress_logs` | `true` | Timestamped milestone per phase. See *Watching an apply*. |
| `cluster_watch_logs` | `true` | Live node state during cluster formation. Same. |
| `assign_management_external_ip` | `false` | A public NSIP exposes NITRO and SSH behind only the password. |
| `assign_client_external_ip` | `true` | Per node — a cluster VIP is striped, so there is no single external address. |

## Things that are deliberate, and why

**The backplane is on `0/1`, the management interface.** On-prem it belongs on a dedicated NIC, and
the `cluster_3node/` reference uses `1/1`. On GCP a VPX auto-configures its NSIP from nic0 and
nothing else, so `1/1` and `1/2` come up with no address at all — and a backplane with no address
carries no heartbeat. A node given `1/2` joins and then sits at `(Adding)` until the 30-minute poll
expires. You cannot fix it afterwards either: `citrixadc_cluster` does not return until every node
reports ACTIVE, so the SNIP that would rescue the node is stuck in the graph behind the resource
waiting for it.

**`addsnip` is not set on the `clusternode` blocks, and must not be.** It is broken in the provider
through at least 3.0.2 — it reads `ownernode` from an attribute absent from the resource schema, so
the SNIP is always submitted unspotted and the ADC rejects it with errorcode 476. `snips.tf` creates
the SNIPs as `citrixadc_nsip` resources instead, where `ownernode` can actually be supplied.

**`can_ip_forward = true` and the `cloud-platform` scope are hardcoded,** not variables. Without IP
forwarding GCP drops every address the cluster floats rather than owns — the CLIP, striped VIPs, the
steering tunnels. The default GCE scope set has no compute access and fails with
`ACCESS_TOKEN_SCOPE_INSUFFICIENT`, which reads like an IAM problem and is not one. Confirm both after
apply with `terraform output instance_settings`.

**NIC declaration order in `adc_instances.tf` is significant.** GCP attaches NICs in order and the VPX
maps them positionally; the first one is always management. Rearranging them breaks everything.

**NSIPs are derived from the CIDR *variables*, not from the subnet data sources,** because a provider
endpoint must be known at plan time. Preconditions compare the declared CIDRs against the real ones
so drift surfaces as a clear message rather than an opaque GCP "IP not in range".

**The progress markers and the cluster watcher are inert by construction, and must stay that way.**
Each depends on real resources; nothing depends on *them*; they create no infrastructure. That is
what makes them safe to leave on in a deployment path where a single badly-placed dependency costs
a 30-minute apply. In particular, `cluster_watch.tf` must never gain a `depends_on
citrixadc_cluster.this` — that would serialise the watcher after the thing it exists to watch, and
it would report nothing until the cluster had already finished.

**`adc_admin_password` must not be empty.** NITRO answers "Password is not specified" with a non-200,
the bootstrap poll reads every non-200 as "not reachable yet", and the run fails 30 minutes later on
a timeout that never mentions credentials. A variable validation rejects it up front.

## Outputs

`cluster_topology`, `clip`, `cluster_endpoint`, `private_nsips`, `private_vips`, `private_snips`,
`public_nsips`, `public_vips`, `networks`, `interfaces`, `backplane_interfaces`, `instance_settings`,
`node_endpoints`, `peering`, `spotted_snips`, `verify_cluster`, `ssh_commands`.

## Security notes

- `terraform.tfvars`, `terraform.tfstate` and any saved `tfplan` are **not** for version control.
  `adc_admin_password` lands in state in plaintext regardless of `sensitive = true`, which only
  masks CLI output — and a saved plan file embeds it too. Delete `tfplan` after applying.
- The password is not stored in `terraform.tfvars`; Terraform asks for it. See
  [The admin password](#the-admin-password) for the three ways to supply it and what each costs.
- Rotating it afterwards is not something this configuration does. Changing the variable and
  re-applying resets it through `citrixadc_password_resetter`, which expects the *instance id* as
  the current password — true only on a freshly booted node. Change it on the ADC instead, then set
  the variable to match so later runs can still authenticate.
- The client firewall opens 80/443 to `0.0.0.0/0`. Narrow it if that is not what you want.

## Teardown

```bash
terraform destroy
```

Nodes are removed from the CLIP before their VMs are destroyed; the CCO goes last. See
`GUIDE.html` → *Tearing it down* for the cases where that does not go cleanly.
