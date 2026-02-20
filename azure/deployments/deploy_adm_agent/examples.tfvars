resource_group_name  = "adm-agent-demo"
virtual_network_name = "terraform-virtual-network"
subnet_name          = "terraform-agent-subnet"

adm_agent_name = "terraform-adm-agent"

virtual_network_address_space = "10.22.0.0/16"

subnet_address_prefix = "10.22.1.0/24"

location = "eastus"

# To provision Citrix ADM Agent version 13.1 use "netscaler-ma-service-agent"
# for 13.0 use "netscaler-130-ma-service-agent"
adm_agent_version_offer = "netscaler-ma-service-agent"

# Don't use `nsroot` or `admin` as the username
adm_agent_admin_username = "agent"
adm_agent_admin_password = "<<enter password>>"

admin_ip_address = "10.10.10.10" #  This ip address will have SSH permission to Manage ADM Agent

managed_disk_type = "StandardSSD_LRS"

serviceurl     = "cocoa.agent.adm.cloud.com"
activationcode = "xxxxxx7-xxx9-1xx4-xxx6-xxxxxxxxxxx0"
