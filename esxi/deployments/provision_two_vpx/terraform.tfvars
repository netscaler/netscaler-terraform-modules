# NetScaler IP addresses for both HA nodes
# Replace with two available IPs in your network
nsip = ["10.106.195.10", "10.106.195.11"]

# Secondary management IP addresses (SNIPs with management access) for HA configuration
# Replace with two additional available IPs in your network
snip = "10.106.195.12"

# Network configuration
# Update these based on your network setup
gw_ip = "10.106.195.1"
subnetmask = "255.255.255.0"

# vSphere/ESXi configuration
vsphere_ip = "10.106.195.4"
vsphere_username = "root"
vsphere_password = "Freebsd123$%^"

# ESXi resource details
# For standalone ESXi, these are typically the default values
# Verify these in your ESXi web UI if deployment fails
datacenter_name = "ha-datacenter"
datastore_name = "Datastore2"
resource_pool_name = "Resources"
resource_host = "10.106.195.4"

# Network name - check ESXi web UI -> Networking
# Common values: "VM Network", "Management Network"
nic_01_network_name = "VM Network"

# VM configuration
virtual_machine_name = "NetScaler-HA"
memory = 2048  # MB
num_cpus = 2

# NetScaler VPX OVF file location
# This should be an HTTP/HTTPS URL to your NetScaler VPX OVF file
# Host this file on 10.101.132.136 using: python3 -m http.server 8080
remote_vpx_ovf_path = "http://10.101.132.136:8080/netscaler-ovf/NSVPX-ESX-14.1-60.57_nc_64.ovf"

# ISO destination folder in datastore
iso_destination_folder = "netscaler-iso"
