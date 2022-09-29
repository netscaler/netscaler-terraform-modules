# ESXi automation scripts

This folder contains terraform configuration scripts to deploy Citrix ADC on ESXi hosts using the vsphere terraform provider.

## Folder structure

* `standalone`: Scripts to deploy a single Citrix ADC instance on ESXi.
* `ha_pair`: Scripts to deploy two Citrix ADCs in High Availability mode.

## Prerequisites

Configuration is based on the preboot config functionality of ADC.
See [here](https://docs.citrix.com/en-us/citrix-adc/current-release/deploying-vpx/install-vpx-on-esx/apply-preboot-userdata-on-esx-vpx.html)
for more information.

For this to work you need a version of ADC that supports this feature.

Additionally we need to create iso images to attach to the ADC VMs as they boot up.
To do this we rely on the `mkisofs` utility available on Linux platforms.
Make sure that terraform runs on a Linux host that has this utility installed.

Also take note that we need to host the OVF and VMDK files in a host that has high speed connectivity with
the target ESXi server. This is to reduce the time it takes to transfer these files.

## ESXi VM configuration

In both use cases covered here we launch ADC with a single interface.

You can add more vSphere networks and network interfaces in the vSphere virtual machine resource.

In all cases the ADCs will be configured with a NSIP and be reachable for further configuration.
The additional configuration can be applied using the [ADC terraform provider](https://registry.terraform.io/providers/citrix/citrixadc).

## HA pair bootstrap

During the bootstrap process of the HA pair there is a race condition as to which node will be Primary and which Secondary.
To remove this race condition we advise to run the terraform apply command with a single thread.

```bash
terraform apply -parallelism=1
```

## Use case index

|**Folder**|**Folder Link**|**Description**|
|--|--|--|
|**Deployments**|[HERE](./deployments/standalone/)|Citrix ADC VPX Standalone deployment|
||[HERE](./deployments/ha_pair/)|Citrix ADC VPX in High Availability **(Recommended for beginners)**|
