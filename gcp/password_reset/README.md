# Default password reset

This folder contains the terraform configuration
to do the default password reset.

This is needed to be able to login with username and password
and to issue NITRO API calls through the terraform Citrix ADC provider.

This configuration should be run once after the HA pair has formed
with target address being the external NSIP address of the
primary node.

After its use the configuration can be destroyed since
for the `citrixadc_password_resetter` resource the destroy
operation is a noop.
