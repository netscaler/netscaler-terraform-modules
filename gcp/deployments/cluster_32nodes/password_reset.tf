# =============================================================================
# Initial password reset
#
# A NetScaler ADC booted from a GCP image comes up with its nsroot password set
# to the GCP instance id, and it refuses every other NITRO call until that
# password has been changed. These resources do that change, against each
# node's own NSIP, before the cluster resource runs.
#
# Thirty-two blocks, one per provider alias in providers.tf, which is the
# NetScaler cluster limit. Nothing below is meant to be read or edited:
# var.node_count alone decides how many run, and the pool is sized so that it
# never has to be extended.
#
# One block per node rather than a single counted resource, because the
# provider meta-argument cannot be interpolated. A fixed pool rather than
# exactly node_count of them, because the set of provider aliases is fixed at
# parse time and cannot depend on a variable.
#
# Blocks at or above node_count have count = 0, so neither the resource nor
# the google_compute_instance lookup in its password field is evaluated.
# =============================================================================

resource "citrixadc_password_resetter" "node0" {
  count    = var.enable_password_reset && var.node_count > 0 ? 1 : 0
  provider = citrixadc.node0

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[0].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node1" {
  count    = var.enable_password_reset && var.node_count > 1 ? 1 : 0
  provider = citrixadc.node1

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[1].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node2" {
  count    = var.enable_password_reset && var.node_count > 2 ? 1 : 0
  provider = citrixadc.node2

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[2].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node3" {
  count    = var.enable_password_reset && var.node_count > 3 ? 1 : 0
  provider = citrixadc.node3

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[3].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node4" {
  count    = var.enable_password_reset && var.node_count > 4 ? 1 : 0
  provider = citrixadc.node4

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[4].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node5" {
  count    = var.enable_password_reset && var.node_count > 5 ? 1 : 0
  provider = citrixadc.node5

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[5].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node6" {
  count    = var.enable_password_reset && var.node_count > 6 ? 1 : 0
  provider = citrixadc.node6

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[6].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node7" {
  count    = var.enable_password_reset && var.node_count > 7 ? 1 : 0
  provider = citrixadc.node7

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[7].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node8" {
  count    = var.enable_password_reset && var.node_count > 8 ? 1 : 0
  provider = citrixadc.node8

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[8].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node9" {
  count    = var.enable_password_reset && var.node_count > 9 ? 1 : 0
  provider = citrixadc.node9

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[9].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node10" {
  count    = var.enable_password_reset && var.node_count > 10 ? 1 : 0
  provider = citrixadc.node10

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[10].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node11" {
  count    = var.enable_password_reset && var.node_count > 11 ? 1 : 0
  provider = citrixadc.node11

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[11].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node12" {
  count    = var.enable_password_reset && var.node_count > 12 ? 1 : 0
  provider = citrixadc.node12

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[12].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node13" {
  count    = var.enable_password_reset && var.node_count > 13 ? 1 : 0
  provider = citrixadc.node13

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[13].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node14" {
  count    = var.enable_password_reset && var.node_count > 14 ? 1 : 0
  provider = citrixadc.node14

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[14].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node15" {
  count    = var.enable_password_reset && var.node_count > 15 ? 1 : 0
  provider = citrixadc.node15

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[15].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node16" {
  count    = var.enable_password_reset && var.node_count > 16 ? 1 : 0
  provider = citrixadc.node16

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[16].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node17" {
  count    = var.enable_password_reset && var.node_count > 17 ? 1 : 0
  provider = citrixadc.node17

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[17].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node18" {
  count    = var.enable_password_reset && var.node_count > 18 ? 1 : 0
  provider = citrixadc.node18

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[18].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node19" {
  count    = var.enable_password_reset && var.node_count > 19 ? 1 : 0
  provider = citrixadc.node19

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[19].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node20" {
  count    = var.enable_password_reset && var.node_count > 20 ? 1 : 0
  provider = citrixadc.node20

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[20].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node21" {
  count    = var.enable_password_reset && var.node_count > 21 ? 1 : 0
  provider = citrixadc.node21

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[21].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node22" {
  count    = var.enable_password_reset && var.node_count > 22 ? 1 : 0
  provider = citrixadc.node22

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[22].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node23" {
  count    = var.enable_password_reset && var.node_count > 23 ? 1 : 0
  provider = citrixadc.node23

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[23].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node24" {
  count    = var.enable_password_reset && var.node_count > 24 ? 1 : 0
  provider = citrixadc.node24

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[24].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node25" {
  count    = var.enable_password_reset && var.node_count > 25 ? 1 : 0
  provider = citrixadc.node25

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[25].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node26" {
  count    = var.enable_password_reset && var.node_count > 26 ? 1 : 0
  provider = citrixadc.node26

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[26].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node27" {
  count    = var.enable_password_reset && var.node_count > 27 ? 1 : 0
  provider = citrixadc.node27

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[27].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node28" {
  count    = var.enable_password_reset && var.node_count > 28 ? 1 : 0
  provider = citrixadc.node28

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[28].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node29" {
  count    = var.enable_password_reset && var.node_count > 29 ? 1 : 0
  provider = citrixadc.node29

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[29].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node30" {
  count    = var.enable_password_reset && var.node_count > 30 ? 1 : 0
  provider = citrixadc.node30

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[30].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}

resource "citrixadc_password_resetter" "node31" {
  count    = var.enable_password_reset && var.node_count > 31 ? 1 : 0
  provider = citrixadc.node31

  username     = var.adc_admin_username
  password     = google_compute_instance.adc[31].instance_id
  new_password = var.adc_admin_password

  depends_on = [time_sleep.adc_boot]
}
