# ESXi NetScaler HA INC Mode Configuration

This Terraform configuration sets up High Availability (HA) in INC (Independent Network Configuration) mode on two NetScaler VPX instances deployed on ESXi.

## Prerequisites

1. Two NetScaler VPX instances must be already deployed using the `provision_two_vpx` deployment
2. Both NetScalers should be reachable and running
3. Default credentials should be `nsroot/nsroot`

## What This Does

This configuration:
- Enables HA INC mode on both NetScaler nodes
- Configures HA node pairing between the two instances
- Sets custom system prompts
- Changes the RPC node password on both nodes for security

## Usage

1. First, deploy the provision_two_vpx to create two NetScaler VPXs:
```bash
cd ../provision_two_vpx
terraform init
terraform apply -parallelism=1 -auto-approve
```

2. Wait for both NetScalers to fully boot (typically 5-10 minutes)

3. Copy the example variables file and customize:
```bash
cd ../ha_inc_mode
cp examples.tfvars terraform.tfvars
# Edit terraform.tfvars with your passwords
```

4. Initialize and apply the HA INC configuration:
```bash
terraform init
terraform apply -auto-approve
```

## Variables

- `adc_admin_username` - NetScaler admin username (default: `nsroot`)
- `adc_admin_password` - NetScaler admin password (must match the password from provision_two_vpx)
- `citrixadc_rpc_node_password` - New RPC node password for secure HA communication

**Note**: The `provision_two_vpx` deployment requires the `adc_management_secondary_ips` variable, which should contain two additional IP addresses in the management subnet for SNIPs with management access. The subnet mask is automatically inherited from the provision_two_vpx configuration.

## After Deployment

You can access either NetScaler node to manage the HA pair:
- Node 1: `https://<nsip[0]>` (from provision_two_vpx deployment)
- Node 2: `https://<nsip[1]>` (from provision_two_vpx deployment)

Check HA status:
- Login to either node
- Navigate to: System → High Availability
- You should see both nodes in sync with INC mode enabled

## Notes

- This configuration uses INC mode, which means each node maintains its own independent network configuration
- RPC node passwords are changed for security - make sure to remember the password you set
- If configuration fails, ensure both NetScalers are accessible and running with default credentials
