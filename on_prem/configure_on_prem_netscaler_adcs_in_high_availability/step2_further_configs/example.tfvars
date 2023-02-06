# primary_netscaler_ip           = "10.10.10.1" # Let us give this IP over CLI as the primary_netscaler_ip may change upon failover

snip         = "10.10.10.3"
snip_netmask = "255.255.255.0"

web_server1_name       = "web-server-red"
web_server1_port       = 80
web_server1_ip         = "10.10.10.4"
web_server1_serivetype = "HTTP"

web_server2_name       = "web-server-green"
web_server2_port       = 80
web_server2_ip         = "10.10.10.5"
web_server2_serivetype = "HTTP"

lbvserver_name        = "demo-lb"
lbvserver_ip          = "10.10.10.6"
lbvserver_port        = 80
lbvserver_servicetype = "HTTP"