# Reset password on NetScaler Node 1
resource "citrixadc_password_resetter" "netscaler1_resetter" {
  username     = "nsroot"
  password     = var.adc_default_password
  new_password = var.adc_admin_password
}

# Reset password on NetScaler Node 2
resource "citrixadc_password_resetter" "netscaler2_resetter" {
  provider     = citrixadc.netscaler2
  username     = "nsroot"
  password     = var.adc_default_password
  new_password = var.adc_admin_password

  depends_on = [citrixadc_password_resetter.netscaler1_resetter]
}

# Configure HA on NetScaler Node 1
resource "citrixadc_hanode" "netscaler1" {
  hanode_id  = 1
  ipaddress  = data.terraform_remote_state.infra.outputs.nsip[1]

  depends_on = [citrixadc_password_resetter.netscaler1_resetter]
}

# Configure HA on NetScaler Node 2
resource "citrixadc_hanode" "netscaler2" {
  provider   = citrixadc.netscaler2
  hanode_id  = 1
  ipaddress  = data.terraform_remote_state.infra.outputs.nsip[0]
  
  depends_on = [
    citrixadc_hanode.netscaler1,
    citrixadc_password_resetter.netscaler2_resetter
  ]
}

# Set system prompt on Node 1
resource "citrixadc_systemparameter" "netscaler1_ns_prompt" {
  promptstring = "%u@%s"

  depends_on = [citrixadc_password_resetter.netscaler1_resetter]
}

# Set system prompt on Node 2
resource "citrixadc_systemparameter" "netscaler2_ns_prompt" {
  provider     = citrixadc.netscaler2
  promptstring = "%u@%s"

  depends_on = [citrixadc_password_resetter.netscaler2_resetter]
}

# Change RPC node password on Node 1 for itself
resource "citrixadc_nsrpcnode" "netscaler1to1_rpc_node" {
  ipaddress = data.terraform_remote_state.infra.outputs.nsip[0]
  password  = var.citrixadc_rpc_node_password
  secure    = "ON"
  
  depends_on = [citrixadc_hanode.netscaler1]
}

# Change RPC node password on Node 1 for Node 2
resource "citrixadc_nsrpcnode" "netscaler1to2_rpc_node" {
  ipaddress = data.terraform_remote_state.infra.outputs.nsip[1]
  password  = var.citrixadc_rpc_node_password
  secure    = "ON"
  
  depends_on = [citrixadc_hanode.netscaler1]
}

# Change RPC node password on Node 2 for Node 1
resource "citrixadc_nsrpcnode" "netscaler2to1_rpc_node" {
  provider  = citrixadc.netscaler2
  ipaddress = data.terraform_remote_state.infra.outputs.nsip[0]
  password  = var.citrixadc_rpc_node_password
  secure    = "ON"
  
  depends_on = [citrixadc_hanode.netscaler2]
}

# Change RPC node password on Node 2 for itself
resource "citrixadc_nsrpcnode" "netscaler2to2_rpc_node" {
  provider  = citrixadc.netscaler2
  ipaddress = data.terraform_remote_state.infra.outputs.nsip[1]
  password  = var.citrixadc_rpc_node_password
  secure    = "ON"
  
  depends_on = [citrixadc_hanode.netscaler2]
}

# Add SNIP with management access on Node 1
resource "citrixadc_nsip" "netscaler1_snip_with_mgmt_access" {
  ipaddress  = data.terraform_remote_state.infra.outputs.snip
  netmask    = data.terraform_remote_state.infra.outputs.subnetmask
  type       = "SNIP"
  mgmtaccess = "ENABLED"
  depends_on = [citrixadc_hanode.netscaler1]
}

