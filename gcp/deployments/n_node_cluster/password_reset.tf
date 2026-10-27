# =============================================================================
# Initial password reset
#
# A NetScaler ADC booted from a GCP image comes up with its nsroot password set
# to the GCP instance id, and it refuses every other NITRO call until that
# password has been changed. This does that change, against each node's own
# NSIP -- or its node_endpoints override -- before the cluster resource runs.
#
# Why curl and not citrixadc_password_resetter: the provider builds the login
# body with Go's json.Marshal, which rewrites & < > as \u0026 \u003c \u003e.
# NITRO does not decode \u escapes, so any password containing one of those
# three characters arrives mangled and the ADC answers errorcode 278 "Invalid
# argument" -- every time, however long you wait. Tested against the VPX:
#
#     raw  Ab&c<d>e!@#$%^*()-_=+[]{};:,.?/~`|1   -> set OK, login OK
#     \u0061 in place of a                -> 354, not decoded
#     \"  or  \\  (JSON escapes)                -> rejected, cannot be set
#
# So the body is written here byte for byte, and " and \ -- which JSON cannot
# carry without the escapes NITRO mishandles -- are refused up front by a
# validation on adc_admin_password.
#
# Per node, retried every 15s for up to reset_timeout seconds:
#   1. log in with adc_admin_password        -> works: already done, stop
#   2. log in with the instance id + new_password   (the normal first-boot path)
#   3. log in with the instance id alone; if that works the image has no forced
#      change pending, so set the password with PUT systemuser instead
# 278 or no answer at all means the node is still coming up; the loop simply
# tries again. Step 1 makes the whole thing idempotent, so a re-run against a
# node that is already done is a no-op.
#
# The password goes to curl on stdin, never on the command line, so it does
# not show up in ps. Terraform suppresses the output of any provisioner that
# touches a sensitive value, so progress and the ADC's answers go to
# password_reset_logs/node<N>.log instead. The password is never written there.
#
# The 32 citrixadc.node* provider aliases in providers.tf are no longer used by
# anything, but stay: a state file from an earlier run may still hold
# citrixadc_password_resetter entries, and Terraform needs their provider
# configuration to drop them.
# =============================================================================

locals {
  reset_timeout = 600
}

resource "terraform_data" "password_reset" {
  count = var.enable_password_reset ? local.node_count : 0

  # A new instance means a new boot-time password, so a new reset.
  triggers_replace = google_compute_instance.adc[count.index].instance_id

  depends_on = [time_sleep.adc_boot]

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]

    environment = {
      NODE_URL  = trimsuffix(local.node_endpoints[count.index], "/")
      ADC_USER  = var.adc_admin_username
      BOOT_PASS = google_compute_instance.adc[count.index].instance_id
      NEW_PASS  = var.adc_admin_password
      DEADLINE  = local.reset_timeout
      LOG       = "${path.module}/password_reset_logs/node${count.index}.log"
    }

    command = <<-EOT
      set -u
      mkdir -p "$(dirname "$LOG")" && : > "$LOG"
      log() { printf '[%s] %s\n' "$(date -u +%H:%M:%SZ)" "$*" >> "$LOG"; }
      field() { printf '%s' "$2" | sed -n "s/.*\"$1\": *\"\{0,1\}\([^\",}]*\).*/\1/p"; }

      # $1 password, $2 optional new_password. Body built with printf so every
      # byte goes out as typed; " and \ are already excluded by validation.
      login() {
        if [ $# -ge 2 ]; then
          printf '{"login":{"username":"%s","password":"%s","new_password":"%s"}}' "$ADC_USER" "$1" "$2"
        else
          printf '{"login":{"username":"%s","password":"%s"}}' "$ADC_USER" "$1"
        fi | curl -s -m 20 -X POST -H 'Content-Type: application/json' \
               --data-binary @- "$NODE_URL/nitro/v1/config/login" 2>/dev/null || true
      }

      if ! command -v curl >/dev/null 2>&1; then
        log "FAILED: no curl on the Terraform host"
        exit 1
      fi

      log "resetting nsroot on $NODE_URL"
      start=$(date +%s)
      while :; do
        r=$(login "$NEW_PASS")
        if [ "$(field errorcode "$r")" = 0 ]; then
          log "ok: $NODE_URL accepts adc_admin_password after $(( $(date +%s) - start ))s"
          exit 0
        fi

        r=$(login "$BOOT_PASS" "$NEW_PASS")
        log "login+new_password: errorcode=$(field errorcode "$r") $(field message "$r")"

        r=$(login "$BOOT_PASS")
        if [ "$(field errorcode "$r")" = 0 ]; then
          sid=$(field sessionid "$r")
          p=$(printf '{"systemuser":{"username":"%s","password":"%s"}}' "$ADC_USER" "$NEW_PASS" |
              curl -s -m 20 -X PUT -H 'Content-Type: application/json' \
                   -H "Cookie: NITRO_AUTH_TOKEN=$sid" --data-binary @- \
                   "$NODE_URL/nitro/v1/config/systemuser" 2>/dev/null || true)
          log "no forced change pending, PUT systemuser: errorcode=$(field errorcode "$p") $(field message "$p")"
        fi

        if [ $(( $(date +%s) - start )) -ge "$DEADLINE" ]; then
          log "FAILED: $NODE_URL still rejects adc_admin_password after $${DEADLINE}s"
          exit 1
        fi
        sleep 15
      done
    EOT
  }
}
