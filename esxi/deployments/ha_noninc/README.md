# ESXi NetScaler HA Non-INC Configuration

This Terraform configuration sets up High Availability (HA) in non-INC mode on two NetScaler VPX instances deployed on ESXi.

## Prerequisites

1. Two NetScaler VPX instances must be already deployed using the `provision_two_vpx` deployment
2. Both NetScalers should be reachable and running


## What This Does

This configuration:
- Changes the admin password on both NetScaler VPX instances from the default password
- Configures HA node pairing between the two instances in non-INC mode
- Sets custom system prompts on both nodes
- Changes the RPC node password on both nodes for security
- Adds a SNIP with management access on Node 1

## Usage

1. First, deploy the provision_two_vpx to create two NetScaler VPXs:
```bash
cd ../provision_two_vpx
terraform init
terraform apply -auto-approve
```

2. Wait for both NetScalers to fully boot (typically 5-10 minutes)

3. Copy the example variables file and customize:
```bash
cd ../ha_noninc
cp examples.tfvars terraform.tfvars
# Edit terraform.tfvars with your passwords
```

4. Initialize and apply the HA non-INC configuration:
```bash
terraform init
terraform apply -auto-approve
```

## Variables

- `adc_admin_username` - NetScaler admin username (default: `nsroot`)
- `adc_default_password` - The default password that the NetScaler VPXs boot up with
- `adc_admin_password` - The new password to set for the NetScaler admin user on both instances
- `citrixadc_rpc_node_password` - New RPC node password for secure HA communication

## After Deployment

You can access either NetScaler node to manage the HA pair:
- Node 1: `https://<nsip[0]>` (from provision_two_vpx deployment)
- Node 2: `https://<nsip[1]>` (from provision_two_vpx deployment)

Check HA status:
- Login to either node
- Navigate to: System → High Availability
- You should see both nodes in sync

## Notes

- This configuration uses non-INC mode, which means the network configuration is synchronized between both nodes
- RPC node passwords are changed for security - make sure to remember the password you set
- If configuration fails, ensure both NetScalers are accessible and running with default credentials
