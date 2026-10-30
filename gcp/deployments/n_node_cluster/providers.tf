provider "google" {
  project = var.project
  region  = var.region
}

# Cluster-wide provider. The endpoint is the CLIP, which does not exist until
# the first node has been bootstrapped; do_login is false so nothing is dialled
# at configure time. The first real connection happens during the bootstrap
# poll, by which point the CLIP is up on the CCO.
provider "citrixadc" {
  endpoint = local.cluster_api_endpoint
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

# =============================================================================
# Per-node aliases, used only for the initial password reset.
#
# Thirty-two of them, which is the NetScaler cluster limit. Nothing below is
# meant to be read or edited: var.node_count alone decides how many are used,
# and the pool is deliberately sized so that it never has to be extended.
#
# The repetition is forced, not stylistic. citrixadc_password_resetter carries
# no endpoint of its own -- its whole schema is username / password /
# new_password -- so the only way to aim it at a particular node is a provider
# alias. Terraform cannot generate those: `provider =` cannot be interpolated,
# and a provider block accepts neither count nor for_each. The alternative
# would be a shell or Python generator, which this deployment does not use.
#
# Slots at or above var.node_count cost nothing. local.provider_endpoints
# gives them a loopback address, their resetter in password_reset.tf is
# counted out, and do_login is false here, so no connection is ever attempted.
#
# Active endpoints default to the pinned NSIPs, which is why the NSIPs must be
# static: a provider endpoint cannot be an unknown value at plan time. Override
# with var.node_endpoints if Terraform reaches the nodes some other way.
# =============================================================================

provider "citrixadc" {
  alias    = "node0"
  endpoint = local.provider_endpoints[0]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node1"
  endpoint = local.provider_endpoints[1]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node2"
  endpoint = local.provider_endpoints[2]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node3"
  endpoint = local.provider_endpoints[3]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node4"
  endpoint = local.provider_endpoints[4]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node5"
  endpoint = local.provider_endpoints[5]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node6"
  endpoint = local.provider_endpoints[6]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node7"
  endpoint = local.provider_endpoints[7]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node8"
  endpoint = local.provider_endpoints[8]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node9"
  endpoint = local.provider_endpoints[9]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node10"
  endpoint = local.provider_endpoints[10]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node11"
  endpoint = local.provider_endpoints[11]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node12"
  endpoint = local.provider_endpoints[12]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node13"
  endpoint = local.provider_endpoints[13]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node14"
  endpoint = local.provider_endpoints[14]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node15"
  endpoint = local.provider_endpoints[15]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node16"
  endpoint = local.provider_endpoints[16]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node17"
  endpoint = local.provider_endpoints[17]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node18"
  endpoint = local.provider_endpoints[18]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node19"
  endpoint = local.provider_endpoints[19]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node20"
  endpoint = local.provider_endpoints[20]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node21"
  endpoint = local.provider_endpoints[21]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node22"
  endpoint = local.provider_endpoints[22]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node23"
  endpoint = local.provider_endpoints[23]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node24"
  endpoint = local.provider_endpoints[24]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node25"
  endpoint = local.provider_endpoints[25]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node26"
  endpoint = local.provider_endpoints[26]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node27"
  endpoint = local.provider_endpoints[27]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node28"
  endpoint = local.provider_endpoints[28]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node29"
  endpoint = local.provider_endpoints[29]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node30"
  endpoint = local.provider_endpoints[30]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}

provider "citrixadc" {
  alias    = "node31"
  endpoint = local.provider_endpoints[31]
  username = var.adc_admin_username
  password = var.adc_admin_password
  do_login = false
}
