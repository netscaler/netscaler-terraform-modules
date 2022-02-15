resource "citrixadc_service" "ssl_service1" {
  servicetype = "SSL"
  name        = var.ssl_service1_name
  ipaddress   = var.ssl_service1_ip
  ip          = var.ssl_service1_ip
  port        = "443"
}

resource "citrixadc_service" "ssl_service2" {
  servicetype = "SSL"
  name        = var.ssl_service2_name
  ipaddress   = var.ssl_service2_ip
  ip          = var.ssl_service2_ip
  port        = "443"
}

resource "citrixadc_lbvserver" "production_lb" {
  name        = var.production_lb_name
  ipv46       = var.production_lb_ip
  port        = "443"
  servicetype = "SSL"
}

resource "citrixadc_sslcertkey" "sslcertkey1" {
  certkey = var.ssl_certkey_name
  cert    = var.ssl_certificate_path
  key     = var.ssl_key_path
}

resource "citrixadc_sslvserver_sslcertkey_binding" "sslvserver_sslcertkey_bind" {
  vservername = citrixadc_lbvserver.production_lb.name
  certkeyname = citrixadc_sslcertkey.sslcertkey1.certkey
}

resource "citrixadc_lbvserver_service_binding" "lbvserver_sslservice1_bind" {
  name        = citrixadc_lbvserver.production_lb.name
  servicename = citrixadc_service.ssl_service1.name
}

resource "citrixadc_lbvserver_service_binding" "lbvserver_sslservice2_bind" {
  name        = citrixadc_lbvserver.production_lb.name
  servicename = citrixadc_service.ssl_service2.name
}
