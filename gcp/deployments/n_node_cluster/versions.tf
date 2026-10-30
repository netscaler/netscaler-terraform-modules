terraform {
  # 1.5.0 for `check` blocks, used in network.tf to warn when Terraform has no
  # network path to the NSIPs it is about to configure. 1.9.0 for validations
  # that reference another variable: adc_admin_password_confirm in variables.tf.
  required_version = ">= 1.9.0"

  required_providers {
    google = {
      source = "hashicorp/google"
    }
    # 2.2.2 is the floor, for two reasons from the provider changelog:
    #
    #   2.2.0  fixed an index-out-of-range panic during multi-node cluster
    #          creation -- i.e. exactly this, three nodes rather than two.
    #   2.2.2  re-registered citrixadc_cluster in the SDKv2 provider so the
    #          resource remains available at all.
    #
    # Not a reason to upgrade: the clusternode addsnip option. It is broken in
    # every version through at least 3.0.2 -- it reads ownernode from an
    # attribute that does not exist in the resource schema, so the SNIP is
    # always submitted unspotted and the ADC rejects it with errorcode 476.
    # snips.tf works around it. See the comment in cluster.tf.
    citrixadc = {
      source  = "citrix/citrixadc"
      version = ">= 2.2.2"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}
