#!/bin/bash

terraform apply -auto-approve -target module.ha_availability_set && \
terraform apply -auto-approve
