# add snip with mgmt access on node 1
resource "citrixadc_nsip" "netscaler1_snip_with_mgmt_access" {
  ipaddress = data.terraform_remote_state.infra.outputs.adc_management_secondary_ips[0]
  netmask = cidrnetmask(var.management_subnet_address_prefix)
  type      = "SNIP"
  mgmtaccess = "ENABLED"
}

# add snip with mgmt access on node 2
resource "citrixadc_nsip" "netscaler2_snip_with_mgmt_access" {
  provider  = citrixadc.netscaler2
  ipaddress = data.terraform_remote_state.infra.outputs.adc_management_secondary_ips[1]
  netmask = cidrnetmask(var.management_subnet_address_prefix)
  type      = "SNIP"
  mgmtaccess = "ENABLED"
}


# add ha node
resource "citrixadc_hanode" "netscaler1" {
  hanode_id = 1
  ipaddress = data.terraform_remote_state.infra.outputs.private_nsips[1]
  inc = "ENABLED"
  depends_on = [ citrixadc_nsip.netscaler1_snip_with_mgmt_access ]
}

# add ha node
resource "citrixadc_hanode" "netscaler2" {
  provider  = citrixadc.netscaler2
  hanode_id = 1
  inc = "ENABLED"
  ipaddress = data.terraform_remote_state.infra.outputs.private_nsips[0]

  depends_on = [citrixadc_hanode.netscaler1]
}

resource "citrixadc_systemparameter" "netscaler1_ns_prompt" {
  promptstring = "%u@%s"
}
resource "citrixadc_systemparameter" "netscaler2_ns_prompt" {
  provider     = citrixadc.netscaler2
  promptstring = "%u@%s"
}

# It is best practice to change the RPC node password
resource "citrixadc_nsrpcnode" "netscaler1to1_rpc_node" {
  ipaddress = data.terraform_remote_state.infra.outputs.private_nsips[0]
  password  = var.citrixadc_rpc_node_password
  secure    = "ON"

  depends_on = [citrixadc_hanode.netscaler1]
}

# It is best practice to change the RPC node password
resource "citrixadc_nsrpcnode" "netscaler1to2_rpc_node" {
  ipaddress = data.terraform_remote_state.infra.outputs.private_nsips[1]
  password  = var.citrixadc_rpc_node_password
  secure    = "ON"

  depends_on = [citrixadc_hanode.netscaler1]
}

# It is best practice to change the RPC node password
resource "citrixadc_nsrpcnode" "netscaler2to1_rpc_node" {
  provider  = citrixadc.netscaler2
  ipaddress = data.terraform_remote_state.infra.outputs.private_nsips[0]
  password  = var.citrixadc_rpc_node_password
  secure    = "ON"

  depends_on = [citrixadc_hanode.netscaler2]
}

# It is best practice to change the RPC node password
resource "citrixadc_nsrpcnode" "netscaler2to2_rpc_node" {
  provider  = citrixadc.netscaler2
  ipaddress = data.terraform_remote_state.infra.outputs.private_nsips[1]
  password  = var.citrixadc_rpc_node_password
  secure    = "ON"

  depends_on = [citrixadc_hanode.netscaler2]
}