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
| `versions.tf` | Terraform ≥ 1.9.0, `citrix/citrixadc` ≥ 2.2.2 (see the comment — both floors are load-bearing). |
| `providers.tf` | The cluster-wide provider (endpoint = CLIP), plus 32 per-node aliases that nothing uses any more — kept so a state file from before the curl reset can still drop its old resetter entries. |
| `variables.tf` | Every input, each with the reasoning behind its default. |
| `locals.tf` | Network/subnet resolution, address derivation, the `cluster_nodes` list. |
| `network.tf` | Networks, subnets, firewall rules, external addresses, two `check` blocks. |
| `peering.tf` | Bidirectional peering to `peer_network`. |
| `adc_instances.tf` | The VPX instances, their NIC order, the optional NITRO login-readiness probe, the boot wait (which also pins the firewall rules for teardown), and all scaling preconditions. |
| `password_reset.tf` | One `terraform_data.password_reset` per node: the nsroot reset, sent with `curl` byte for byte. Log per node in `password_reset_logs/`. |
| `cluster.tf` | The single `citrixadc_cluster` resource and its poll timeouts. |
| `snips.tf` | Spotted SNIPs and `citrixadc_nsconfig_save`. |
| `progress.tf` | Six inert markers that print a timestamped line as each phase of the apply completes. |
| `cluster_watch.tf` | Read-only NITRO poller that logs node state to `cluster_watch.log` *while* the cluster is forming. |
| `outputs.tf` | Topology, addresses, and ready-made verification commands. |
| `terraform.tfvars.example` | Annotated starting point. Copy to `terraform.tfvars`. |

Three HTML companions sit alongside these — open them in a browser:

- **`GUIDE.html`** — how to modify the scripts: resizing, the settings you will actually change,
  what not to touch, recipes, troubleshooting, teardown.
- **`ISSUES.html`** — the failures encountered building this, phase by phase, and their fixes.
  Read this before debugging an apply of your own.
- **`REPORT.html`** — per-file script reference.

## Prerequisites

- Terraform ≥ 1.9.0 (the password confirmation compares two variables, which needs 1.9) and
  credentials for the target GCP project (`gcloud auth application-default login`).
- A NetScaler ADC image in the project. **Validate it standalone first** — boot one throwaway VM from
  it and confirm port 22 answers within ~10 minutes. A bad image costs a full apply cycle.
- Spare network quota. This creates 3 VPCs against a 50-per-project limit:
  `gcloud compute networks list | wc -l`. Or set `use_existing_networks = true`.
- vCPU quota for `node_count × machine_type`, and a machine type with at least 3 vCPUs (GCP permits
  one NIC per vCPU).
- A route from the Terraform host to the NSIPs — see below.
- `/bin/sh` and `curl` on the Terraform host. The password reset runs through them and **cannot**
  work without either — a missing one fails the reset. `progress_logs`, `cluster_watch_logs` and
  `adaptive_boot_wait` also run through `/bin/sh`, but tolerate a missing `curl`. In practice: run
  Terraform from Linux, macOS or WSL, not from plain Windows.

## Quick start

```bash
cp terraform.tfvars.example terraform.tfvars
# edit: project, region, zone, image, peer_network, controlling_subnet, public_ssh_key_file

terraform init
terraform apply                # asks for the ADC password, then asks again to confirm
```

`adc_admin_password` has no default and is not set in `terraform.tfvars`, so Terraform asks for it —
and then for `adc_admin_password_confirm`, which must match. One answer covers the whole deployment —
see [The admin password](#the-admin-password).

Budget 30–45 minutes. Most of it is the `adc_boot_wait` (10 min default) plus the reboot each node
takes when it joins the cluster. Set `adaptive_boot_wait = true` to spend what the boot actually
costs instead of the worst case — typically 3–5 minutes back per apply.

## The admin password

`adc_admin_password` is **not** written in `terraform.tfvars`. The variable has no default, so
Terraform asks for it, and that one answer is used everywhere: the password reset, the cluster
resource, the SNIPs and the watcher all read the same variable. There is no per-node password in
this configuration — nothing to keep in sync.

Every `apply` **and** `destroy` asks twice:

```
var.adc_admin_password
  nsroot password for all ADC nodes. Any special character except " and \.
  Asked twice, on apply and destroy. Destroy needs the same password.

  Enter a value:

var.adc_admin_password_confirm
  Type the same password again to confirm.

  Enter a value:
```

If the two differ, Terraform stops before changing anything: *"The two passwords do not match.
Nothing was changed -- run the command again."* Terraform cannot tell apply from destroy, so the
confirmation is on both — and a typo costs either way: on apply it sets a password nobody knows, on
destroy it fails the teardown partway through.

**Characters.** Anything printable works — `& < > ! @ # $ % ^ * ( ) [ ] { } ; : , . ? / ~ | `` ` ``
included — **except `"` and `\`**, which a validation rejects. NITRO cannot carry those two: JSON
can only send them as escape sequences, and NITRO does not decode escapes. See *Things that are
deliberate* for why the reset is done with `curl`.

Ways to supply it, all the same variable:

| How | When to use it | Prompts? |
|---|---|---|
| `terraform apply` / `terraform destroy` | Normal use. | Twice per command |
| `terraform plan -out=tfplan` then `terraform apply tfplan` | To apply exactly what you reviewed. The saved plan carries the value — delete it afterwards. | Twice, at `plan` only |
| `export TF_VAR_adc_admin_password='...'` **and** `TF_VAR_adc_admin_password_confirm` | CI, or repeated runs in one shell. Use single quotes, or the shell eats `$` and `!`. | Never |

Be clear about what prompting does and does not buy you:

- **It does** keep the password out of the config file — the thing that gets committed by accident.
- **It does not** mask your typing. Terraform echoes interactive variable input in plaintext even
  for a `sensitive` variable.
- **It does not** keep the password out of `terraform.tfstate`, which is plaintext regardless.
  `sensitive = true` only masks CLI output.

Failure modes the validations catch up front, all of them specific to typing at a prompt:

- **An empty password.** Pressing Enter gets you a 30-minute apply that dies on `timeout waiting
  for cluster operation to complete`, naming nothing to do with credentials. See *Things that are
  deliberate*.
- **Leading or trailing whitespace.** Invisible when you re-type it to compare, and it produces an
  auth failure that arrives much later than the typo did.
- **`"` or `\`** in the password, and **two answers that differ**.

> **Forgot the password?** You can still tear down — see [Teardown](#teardown).

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
  logs each transition, so a node stuck at `(Adding)` shows up within a minute instead of at the
  30-minute timeout. It stops by itself once every node is ACTIVE/UP.

  Its lines go to **`cluster_watch.log`**, not the console: Terraform suppresses all output from a
  provisioner that touches a sensitive value, and the watcher needs the password. Follow it from a
  second shell:

  ```
  $ tail -f cluster_watch.log
  ~~  [09:21:40Z +412s]  node0=ACTIVE/UP  node1=(Adding)/NOT UP  node2=(Adding)/NOT UP
  ```

The password reset logs the same way, for the same reason — one file per node in
`password_reset_logs/node<N>.log`, with the ADC's answer to each attempt. It never writes the
password itself.

The markers and the watcher are read-only, create no infrastructure, and nothing in the graph
depends on them — they cannot change what is built or in what order, and every failure path in the
watcher exits 0. The watcher shares the cluster resource's dependencies rather than depending on the
cluster, so Terraform schedules it *alongside* the thing it reports on. The markers re-run on every
apply by design, which is why `progress.tf` shows six trivial changes in every plan; set
`progress_logs = false` to silence them.

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
route to either**, and the apply builds every instance and then the password reset retries for 10
minutes and fails, with nothing but empty answers in `password_reset_logs/`.

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

`password_reset.tf` is a single resource counted by `node_count`. `providers.tf` still carries a
fixed pool of 32 per-node aliases from when the reset used `citrixadc_password_resetter`, which had
no endpoint attribute and could only be aimed at a node through an alias. Nothing uses them now; they
stay because Terraform needs a resource's provider configuration to drop it from state, and a state
file from before the change may still hold old resetter entries. Every alias is `do_login = false`,
and unused slots point at loopback — they dial nothing. **Don't edit `providers.tf`.**

You hit these before you hit 32: GCP vCPU quota, the size of the management subnet, and
`cluster_priority_base + node_count - 1 ≤ 31`. Preconditions in `adc_instances.tf` catch the last one,
plus CLIP/NSIP collisions and list-length mismatches.

### Going to 32 nodes

32 is the one size where the priority range runs out, because the ADC accepts priorities **0–31
inclusive** and this configuration assigns `cluster_priority_base + node_id`:

```
cluster_priority_base = 0     # REQUIRED at node_count = 32 — priorities 0..31
node_count            = 32
```

At the default base of `1`, 32 nodes would need priorities 1–32, and 32 is one past what the ADC
takes. The precondition rejects it at plan time with a message naming the value to use. The general
rule is **`node_count ≤ 32 - cluster_priority_base`**. Priority `0` is not special — lower simply
wins the CCO election, so node 0 still leads.

Two things that bite at this size and are *not* caught at plan time:

- **Quota.** 32 × `n2d-standard-8` is **256 vCPUs**, and `assign_client_external_ip = true` means
  **32 regional external addresses**. Both are rejected by GCP mid-apply, after instances have
  started being created. Check both before you start.
- **Duration.** Node joins are sequential and each one reboots the node, so formation scales with
  `node_count` — budget **hours**, not the 30–45 minutes a 3-node run takes. The provider's
  `node_add_total_timeout` is per node-add, not for the whole set, so it does not need raising, but
  `cluster_watch_timeout` does or the watcher goes quiet long before the apply ends. Raising it
  costs nothing: the watcher stops as soon as every node is UP, so the timeout is only a cap.

## Key variables

Required, no default: `project`, `region`, `zone`, `image`, `public_ssh_key_file`,
`management_subnet_cidr_block`, `client_subnet_cidr_block`, `server_subnet_cidr_block`,
`controlling_subnet`, `adc_admin_password`, `adc_admin_password_confirm`.

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
| `cluster_priority_base` | `1` | Node 0 gets this; lowest wins the CCO election. **Caps cluster size at `32 - base`** — a 32-node cluster needs `0`. |
| `adc_boot_wait` | `600s` | A VPX regularly needs 6–10 minutes before NITRO answers. Ignored when `adaptive_boot_wait` is on, except as the no-`curl` fallback. |
| `adaptive_boot_wait` | `false` | Poll each NSIP until a NITRO login is accepted (anything but errorcode 278) instead of sleeping the full `adc_boot_wait`, then wait only `adc_boot_settle` (`90s`) on top. Off by default because the fixed wait is known-good; the probe itself can never fail an apply. |
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

**The password reset uses `curl`, not `citrixadc_password_resetter`.** The provider builds the login
body with Go's `json.Marshal`, which rewrites `&` `<` `>` as `\u0026` `\u003c` `\u003e`. NITRO does
not decode `\u` escapes, so any password containing one of those three characters fails with
errorcode 278 *"Invalid argument"* — every time, however long you wait, which makes it look like a
timing problem. `password_reset.tf` writes the body itself, so every byte goes out as typed. Per node,
retried every 15 s for up to 10 minutes, it: (1) tries `adc_admin_password` and stops if it already
works, so re-runs are no-ops; (2) logs in with the instance id plus `new_password`, the normal
first-boot path; (3) if the instance id logs in with no change pending (some custom images), sets
the password with `PUT systemuser` instead. A 278 or no answer means the node is still booting, and
it simply tries again. It aims at `node_endpoints` when set, the NSIP otherwise.

**The boot wait depends on the firewall rules.** Every NITRO resource sits downstream of
`time_sleep.adc_boot`, so listing the rules there makes destroy remove them *last*. Without it,
nothing depended on them and destroy deleted them in its opening seconds — cutting the Terraform
host off from the CLIP while `citrixadc_cluster` was still removing nodes. The provider then polled
a CLIP it could not reach for 10 minutes, failed with `Unable to delete cluster node 1: timeout
waiting for cluster operation to complete`, and a second destroy was needed.

## Outputs

`cluster_topology`, `clip`, `cluster_endpoint`, `private_nsips`, `private_vips`, `private_snips`,
`public_nsips`, `public_vips`, `networks`, `interfaces`, `backplane_interfaces`, `instance_settings`,
`node_endpoints`, `peering`, `spotted_snips`, `verify_cluster`, `ssh_commands`.

## Security notes

- `terraform.tfvars`, `terraform.tfstate` and any saved `tfplan` are **not** for version control.
  `adc_admin_password` lands in state in plaintext regardless of `sensitive = true`, which only
  masks CLI output — and a saved plan file embeds it too. Delete `tfplan` after applying.
- The password is not stored in `terraform.tfvars`; Terraform asks for it. See
  [The admin password](#the-admin-password) for the ways to supply it and what each costs.
- Rotating it afterwards is not something this configuration does. The reset runs once per
  instance — it only re-runs when an instance is replaced — so typing a new value at a later apply
  changes nothing on the nodes, and every NITRO call then fails to authenticate. Change it on the
  ADC instead, then use the new value at the prompt so later runs can still authenticate.
- `password_reset_logs/` and `cluster_watch.log` hold ADC responses, never the password, but keep
  them out of git along with the rest.
- The client firewall opens 80/443 to `0.0.0.0/0`. Narrow it if that is not what you want.

## Teardown

```bash
terraform destroy              # asks for the password twice, like apply
```

Answer with the password the nodes actually carry: teardown logs in to remove nodes from the CLIP
before destroying the VMs, and the CCO goes last. The firewall rules and peering go after the
cluster, so one destroy is enough.

**Forgot the password?** The GCP resources do not need it — only the `citrixadc_*` resources do, and
their configuration disappears with the VMs anyway. Make Terraform forget them, then destroy with a
placeholder:

```bash
cp terraform.tfstate terraform.tfstate.before-rm      # backup first
terraform state list | grep '^citrixadc_' | xargs -r -I{} terraform state rm '{}'
terraform destroy -refresh=false -var adc_admin_password=x -var adc_admin_password_confirm=x
```

`state rm` touches neither the ADCs nor GCP; it only edits the state. See `GUIDE.html` →
*Tearing it down* for the other cases where a destroy does not go cleanly.
