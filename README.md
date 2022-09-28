# Citrix ADC Terraform scripts for deployment

This repository contains terraform scripts for automating Citrix ADC
deployment on AWS, Azure, GCP and ESX.`aws` , `azure`, `gcp` and `esxi` contains scripts for deploying ADC VPX in their resepctive environment. 
It also contains the necessary documentation, refer to each folder's README file for more information.The intent is to be utilized as starting points for a more custom configuration that will match the user's needs.

Post a successful deployment of VPX in your environment,leverage [Citrix ADC Terraform provider](https://github.com/citrix/terraform-provider-citrixadc) to configure ADC with load balancing , content switching, WAF etc. 

> :round_pushpin:Learn more about Citrix ADC Automation [here](https://docs.citrix.com/en-us/citrix-adc/current-release/deploying-vpx/citrix-adc-automation.html)

> :round_pushpin:For ADC configurations post deployment , check out [ADC Terraform Provider](https://github.com/citrix/terraform-provider-citrixadc) or [Hashicorp registry](https://registry.terraform.io/providers/citrix/citrixadc/latest)

> :envelope: For any immediate issues or help , reach out to us at appmodernization@citrix.com !
