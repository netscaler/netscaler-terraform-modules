# Usage

## Step-1 Install the Required Plugins

* The terraform needs plugins to be installed in local folder so, use `terraform init` - It automatically installs the required plugins from the Terraform Registry.

## Step-2 Applying the Configuration

* Modify the `main.tf` (if necessary) and `examples.tfvars` to suit your Azure configuration and Citrix ADC deployment.
* Use `terraform plan -var-file examples.tfvars` to review the plan
* Use `terraform apply -var-file examples.tfvars` to apply the configuration.

## Step-3 Updating your configuration

* Modify the set of resources (if necessary)
* Use `terraform plan -var-file examples.tfvars` and `terraform apply -var-file examples.tfvars` to review and update the changes respectively.

## Step-4 Destroying your Configuration

* To destroy the configuration use `terraform destroy -var-file examples.tfvars`.