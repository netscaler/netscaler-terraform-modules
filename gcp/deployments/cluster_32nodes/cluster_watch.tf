# =============================================================================
# Cluster formation watcher
#
# citrixadc_cluster.this blocks for 10-15 minutes and prints nothing but
# "Still creating...". All the interesting state -- which node has been
# declared, which is rebooting, which has gone ACTIVE -- lives on the CCO and
# is only visible if something asks.
#
# This asks. It depends on exactly what the cluster resource depends on and on
# nothing else, so Terraform schedules it ALONGSIDE the cluster rather than
# after it, and it reports while the cluster is still forming.
#
#     resetters + time_sleep ---> citrixadc_cluster.this   (does the work)
#                            \--> cluster_watch            (reports on it)
#
# Nothing depends on this resource, it creates no infrastructure, and it is
# read-only over NITRO (GET /config/clusternode). It cannot affect what the
# cluster resource does. Every failure path exits 0 -- a watcher that breaks an
# apply would be worse than no watcher.
#
# It polls node 0's NSIP rather than the CLIP, because the CLIP does not exist
# until node 0 has finished bootstrapping and the first few minutes are exactly
# what you want to see.
#
# Needs curl on the Terraform host. No jq or python -- the JSON is picked apart
# with sed so this works on a bare VM.
# =============================================================================

resource "terraform_data" "cluster_watch" {
  count = var.cluster_watch_logs ? 1 : 0

  triggers_replace = timestamp()

  # Identical to citrixadc_cluster.this's dependencies, so the two start
  # together. Do NOT add citrixadc_cluster.this here -- that would serialise
  # the watcher after the thing it is supposed to be watching.
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

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]

    # Credentials go through the environment rather than the command line, so
    # they do not show up in `ps` on the Terraform host. They are already in
    # terraform.tfstate in plaintext either way -- see the README.
    environment = {
      NITRO_USER = var.adc_admin_username
      NITRO_PASS = var.adc_admin_password
    }

    command = <<-EOT
      set -u

      ip0="${local.nsips[0]}"
      want=${local.node_count}
      cap=${var.cluster_watch_timeout}
      int=${var.cluster_watch_interval}

      if ! command -v curl >/dev/null 2>&1; then
        echo "  ~~  cluster watch: no curl on this host, skipping"
        exit 0
      fi

      start=$(date +%s)
      prev=""

      echo "  ~~  cluster watch: polling $ip0 every $int s, expecting $want node(s) ACTIVE/UP"
      echo "  ~~  (read-only; nothing depends on this. The cluster forms whether or not it reports.)"

      while [ $(( $(date +%s) - start )) -lt $cap ]; do
        j=$(curl -s -m 10 \
              -H "X-NITRO-USER: $NITRO_USER" \
              -H "X-NITRO-PASS: $NITRO_PASS" \
              "http://$ip0/nitro/v1/config/clusternode" 2>/dev/null || true)

        if [ -z "$j" ]; then
          line="no answer yet from $ip0 -- node 0 is still bootstrapping or rebooting"
        else
          # One node object per line, then pull the three fields that matter.
          line=$(echo "$j" | tr '}' '\n' | while IFS= read -r l; do
            id=$(echo "$l" | sed -n 's/.*"nodeid":"\([0-9]*\)".*/\1/p')
            [ -z "$id" ] && continue
            ms=$(echo "$l" | sed -n 's/.*"masterstate":"\([A-Za-z_()]*\)".*/\1/p')
            hl=$(echo "$l" | sed -n 's/.*"health":"\([A-Za-z]*\)".*/\1/p')
            printf 'node%s=%s/%s  ' "$id" "$${ms:-?}" "$${hl:-?}"
          done)
          [ -z "$line" ] && line="cluster instance not created yet"
        fi

        # Print on change only. A heartbeat every poll would bury the three or
        # four transitions that actually tell you something.
        if [ "$line" != "$prev" ]; then
          printf '  ~~  [%s +%ss]  %s\n' \
            "$(date -u +%H:%M:%SZ)" "$(( $(date +%s) - start ))" "$line"
          prev="$line"
        fi

        # All nodes UP means the cluster is formed; stop watching. The cluster
        # resource will return on its own a moment later.
        ups=$(printf '%s' "$line" | grep -o '/UP' | wc -l | tr -d ' ')
        if [ "$ups" -ge "$want" ]; then
          printf '  ~~  [%s +%ss]  all %s node(s) ACTIVE/UP -- cluster formed\n' \
            "$(date -u +%H:%M:%SZ)" "$(( $(date +%s) - start ))" "$want"
          exit 0
        fi

        sleep $int
      done

      echo "  ~~  cluster watch: giving up after $cap s. This says nothing about the"
      echo "  ~~  cluster itself -- citrixadc_cluster.this has its own 30m budget and"
      echo "  ~~  will report the real outcome."
      exit 0
    EOT
  }
}
