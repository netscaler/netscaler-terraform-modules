<!-- ## Citrix ADC  -->
## Citrix ADC 3 Network Interface deployment on existing Resource Group, Virtual Network and 3-subnets.

This folder contains the configuration scripts to deploy
* A single Citrix ADC instance with 3 NICs on existing Resource Group, Virtual Network and 3-subnets.
* A ubuntu bastion host with 1 NIC.

## Files Structure
* `main.tf` describes the actual config objects to be created. The attributes of these resources are either hard coded or looked up from input variables in `examples.tfvars`
* `variables.tf` describes the input variables to the terraform config. These can have defaults
* `versions.tf` is used to specify the contains version requirements for Terraform and providers.
* `examples.tfvars` has the variable inputs specified in `variables.tf`
* `outputs.tf` contains some outputs from the resources created in `main.tf`

## Usage

### Step-1 Install the Required Plugins
* The terraform needs plugins to be installed in local folder so, use `terraform init` - It automatically installs the required plugins from the Terraform Registry.

### Step-2 Applying the Configuration 
* Modify the `main.tf` (if necessary) and `examples.tfvars` to suit your own Azure configuration and Citrix ADC deployment. 
* Use `terraform plan -var-file examples.tfvars` to see and verify the plan that is to be applied
* Use `terraform apply -var-file examples.tfvars` to Apply the configuration.

### Step-3 Updating your configuration
* Modify the set of resources (if necessary)
* Use `terraform plan -var-file examples.tfvars` and `terraform apply -var-file examples.tfvars` to verify and Apply the changes respectively.

### Step-4 Destroying your Configuration
* To destroy the configuration that you built now use `terraform destroy -var-file examples.tfvars` to destroy the configuration.