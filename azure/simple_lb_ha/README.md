# Simple Load Balancing setup

This terraform configuration script deploys two Ubuntu Linux images
with an apache server setup that responds to HTTP requests with an
identifying string.

It also uses the terraform citrixadc provider for configuring the
load balancing setup on the target Citrix ADC HA pair.

This setup is meant to be used as a quick verification that the
Citrix ADC HA deployment is working as expected and is not part of
the main Citrix ADC deployment.

Since this is meant to be applied to a HA pair we have two instances
of the `citrixadc` provider with aliases `node0` and `node1` corresponding
to the HA pair instances.

The input variable `ha_primary_node_index` determines which of the two
`citrixadc` providers will be used. The default value is `0` since this
is the expected setup after having deployed the HA pair with one of the
provided scripts.

After the initial setup you can manually `force ha failover` to verify
that backend services are reachable after a fail over.
 
The citrixadc terraform provider repository can be found [here](https://github.com/citrix/terraform-provider-netscaler).

## Backend service manual configuration

The scripts contain a `null_resource` which will configure
the network interface of each backend ubuntu node and
also launch the Apache web server so that backend services
are registered as up from the citrix ADC SNIP address.

If for some reason the configuration fails here is the list of the
steps to apply manually to each ubuntu node.

* Install apache web server `sudo apt update && sudo apt install apache2`
* Optional: add custom index page to each ubuntu node `sudo echo "Hello from backend server <node_number>" > /var/www/html/index.html`

## Verifiation of operation

When you do a GET request from the internet to the public ip address of the Azure Load Balancer
you should see the backend service message along with the node id.

Something like the following command

```
curl http://<alb_public_ip>
```

should show the backend service messages in round robin fashion.
