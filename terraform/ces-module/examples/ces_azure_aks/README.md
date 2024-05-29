# Usage

# Secret configuration
- Get Azure credentials
  - `az login --scope https://graph.microsoft.com//.default`
  - `az ad sp create-for-rbac --skip-assignment`
  - Template `appId` and `password` with `secretVars.tfvars.template`
- Template EcoSystem credentials with `secretVars.tfvars.template`

# General configuration (not mandatory)

If you wish for example to create the cluster in another region you should template `vars.tfvars.template`.
See `variables.tf` for possibilities.

# Create cluster

- Init with `terraform init`
- Check plan with `terraform plan -var-file=secretVars.tfvars` or `terraform plan -var-file=secretVars.tfvars -var-file=vars.tfvars`
- Apply with `terraform apply -var-file=secretVars.tfvars` or `terraform apply -var-file=secretVars.tfvars -var-file=vars.tfvars`

# Get kubeconfig

- `az aks get-credentials --resource-group test-terraform-module-rg --name test-terraform-module-aks`

# Delete cluster

- `terraform destroy -var-file=secretVars.tfvars` or `terraform destroy -var-file=secretVars.tfvars -var-file=vars.tfvars`