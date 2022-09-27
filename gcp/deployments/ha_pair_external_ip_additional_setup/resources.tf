resource "citrixadc_nsip" "primary_vip" {

    provider = citrixadc.primary

    ipaddress = var.primary_vip_address
    netmask = var.primary_vip_netmask
    type = "VIP"
}

resource "citrixadc_nsip" "secondary_vip_on_primary" {

    provider = citrixadc.primary

    ipaddress = var.secondary_vip_address
    netmask = var.secondary_vip_netmask
    type = "VIP"
}

resource "citrixadc_nsip" "primary_snip" {

    provider = citrixadc.primary

    ipaddress = var.primary_snip_address
    netmask = var.primary_snip_netmask
    type = "SNIP"
}

resource "citrixadc_nsip" "secondary_vip" {

    provider = citrixadc.secondary

    ipaddress = var.secondary_vip_address
    netmask = var.secondary_vip_netmask
    type = "VIP"
}

resource "citrixadc_nsip" "secondary_snip" {

    provider = citrixadc.secondary

    ipaddress = var.secondary_snip_address
    netmask = var.secondary_snip_netmask
    type = "SNIP"
}

resource "citrixadc_ipset" "primary_ipset" {
  provider = citrixadc.primary

  name = var.ipset_name
  nsipbinding = [
    var.secondary_vip_address
  ]
  depends_on = [citrixadc_nsip.secondary_vip_on_primary]
}

resource "citrixadc_ipset" "secondary_ipset" {
  provider = citrixadc.secondary

  name = var.ipset_name
  nsipbinding = [
    var.secondary_vip_address
  ]
  depends_on = [citrixadc_nsip.secondary_vip]
}

resource "citrixadc_lbvserver" "frontend_lbvserver" {
  provider = citrixadc.primary

  name = "frontend"
  ipv46 = citrixadc_nsip.primary_vip.ipaddress
  servicetype = "HTTP"
  port = 80
  ipset = var.ipset_name

  depends_on = [
    citrixadc_ipset.primary_ipset,
    citrixadc_ipset.secondary_ipset
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
