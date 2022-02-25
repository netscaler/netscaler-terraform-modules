resource "citrixadc_service" "service1" {
  servicetype = "HTTP"
  name        = var.service1_name
  ipaddress   = var.service1_ip
  ip          = var.service1_ip
  port        = var.service1_port
}

resource "citrixadc_service" "service2" {
  servicetype = "HTTP"
  name        = var.service2_name
  ipaddress   = var.service2_ip
  ip          = var.service2_ip
  port        = var.service1_port
}

resource "citrixadc_lbvserver" "production_lb" {
  depends_on = [ citrixadc_sslparameter.default ]
  name        = var.production_lb_name
  ipv46       = var.production_lb_ip
  port        = "443"
  servicetype = "SSL"
  ciphers =  ["DEFAULT"] #TODO: Ask George, DEFAULT has to be by default
  sslprofile = "ns_default_ssl_profile_secure_frontend"
}

resource "citrixadc_systemfile" "sslcert_copy" {
    filename = "sslcert.pem"
    filelocation = "/var/tmp"
    filecontent = file(var.ssl_certificate_path)
}

resource "citrixadc_systemfile" "sskkey_copy" {
    filename = "sslkey.ky"
    filelocation = "/var/tmp"
    filecontent = file(var.ssl_key_path)
}

resource "citrixadc_sslcertkey" "sslcertkey1" {
  certkey = var.ssl_certkey_name
  cert    = format("%s/%s", citrixadc_systemfile.sslcert_copy.filelocation, citrixadc_systemfile.sslcert_copy.filename)
  key     = format("%s/%s", citrixadc_systemfile.sskkey_copy.filelocation, citrixadc_systemfile.sskkey_copy.filename)
}

resource "citrixadc_sslvserver_sslcertkey_binding" "sslvserver_sslcertkey_bind" {
  vservername = citrixadc_lbvserver.production_lb.name
  certkeyname = citrixadc_sslcertkey.sslcertkey1.certkey
}

resource "citrixadc_lbvserver_service_binding" "lbvserver_sslservice1_bind" {
  name        = citrixadc_lbvserver.production_lb.name
  servicename = citrixadc_service.service1.name
}

resource "citrixadc_lbvserver_service_binding" "lbvserver_sslservice2_bind" {
  name        = citrixadc_lbvserver.production_lb.name
  servicename = citrixadc_service.service2.name
}

resource "citrixadc_sslparameter" "default" {
  defaultprofile = "ENABLED"
}

