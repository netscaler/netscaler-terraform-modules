#!/bin/bash

terraform apply -auto-approve -target module.standalone_3nic && \
terraform apply -auto-approve
