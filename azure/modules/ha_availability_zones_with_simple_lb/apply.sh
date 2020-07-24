#!/bin/bash

terraform apply -auto-approve -target module.ha_availability_zones && \
terraform apply -auto-approve
