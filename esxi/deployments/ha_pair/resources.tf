data "vsphere_datacenter" "dc" {
  name = var.datacenter_name
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# https://github.com/hashicorp/terraform-provider-vsphere/issues/262#issuecomment-348644869
# Every cluster will have a default `Resources` resource_pool
data "vsphere_resource_pool" "pool" {
  name          = var.resource_pool_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "host" {
  name          = var.resource_host
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "nic_01" {
  name          = var.nic_01_network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Create iso file

resource "null_resource" "makeiso" {
  provisioner "local-exec" {
    command = format("./process_userdata.py --nsip %s --other-node-nsip %s --netmask %s --gateway %s --output-dir %s-%s", var.nsip[count.index], var.nsip[count.index == 0 ? 1:0], var.subnetmask, var.gw_ip, var.iso_output_dir, count.index + 1)
  }
  count = 2
}

# Upload iso file to datastore

resource "vsphere_file" "upload_iso" {
  datacenter = var.datacenter_name
  datastore = var.datastore_name
  source_file = format("%s-%s.iso", var.iso_output_dir, count.index + 1)
  destination_file = format("%s/%s-%s.iso", var.iso_destination_folder, var.iso_output_dir, count.index + 1)
  create_directories = true

  count = 2

  depends_on = [null_resource.makeiso]
}

# https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs/resources/virtual_machine
resource "vsphere_virtual_machine" "citrixVPX" {
  name             = format("%s-%s", var.virtual_machine_name, count.index + 1)
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  # folder - (Optional) The path to the folder to put this virtual machine in, relative to the datacenter that the resource pool is in.
  # folder = "test-vapp"
  host_system_id             = data.vsphere_host.host.id
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0
  datacenter_id              = data.vsphere_datacenter.dc.id

  network_interface {
    network_id = data.vsphere_network.nic_01.id
  }

  # Add more network_interface blocks here

  scsi_type = "lsilogic"

  num_cpus = var.num_cpus
  memory   = var.memory # in MBs


  # https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs/resources/virtual_machine#creating-vm-from-deploying-a-ovfova-template
  ovf_deploy {
    remote_ovf_url           = var.remote_vpx_ovf_path
    enable_hidden_properties = true
    allow_unverified_ssl_cert = true

  }

  cdrom {
    datastore_id  = data.vsphere_datastore.datastore.id
    path = format("%s/%s-%s.iso", var.iso_destination_folder, var.iso_output_dir, count.index + 1)
  }
  
  count = 2
  depends_on = [vsphere_file.upload_iso]
}


# output "nsip" {
#   value = vsphere_virtual_machine.citrixVPX.*.guest_ip_addresses.0
# }
