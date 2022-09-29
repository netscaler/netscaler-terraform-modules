resource "citrixadc_nsip" "primary_alias_vip" {

    provider = citrixadc.primary

    ipaddress = var.alias_vip_address
    netmask = var.alias_vip_netmask
    type = "VIP"
}

resource "citrixadc_nsip" "primary_snip" {

    provider = citrixadc.primary

    ipaddress = var.primary_snip_address
    netmask = var.primary_snip_netmask
    type = "SNIP"
}

resource "citrixadc_nsip" "secondary_alias_vip" {

    provider = citrixadc.secondary

    ipaddress = var.alias_vip_address
    netmask = var.alias_vip_netmask
    type = "VIP"
}

resource "citrixadc_nsip" "secondary_snip" {

    provider = citrixadc.secondary

    ipaddress = var.secondary_snip_address
    netmask = var.secondary_snip_netmask
    type = "SNIP"
}

resource "citrixadc_lbvserver" "frontend_lbvserver" {

  provider = citrixadc.primary

  name = "frontend"
  ipv46 = var.alias_vip_address
  servicetype = "HTTP"
  port = 80
  
  depends_on = [
    citrixadc_nsip.primary_alias_vip,
    citrixadc_nsip.secondary_alias_vip
  ]
}

resource "citrixadc_service" "backend_service" {

  provider = citrixadc.primary

  name = "backend"
  port = 80
  ip = var.backend_service_address
  servicetype = "HTTP"
  lbvserver = citrixadc_lbvserver.frontend_lbvserver.name
}
