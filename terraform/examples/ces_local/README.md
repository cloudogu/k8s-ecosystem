# Usage

This example just uses the current configured `KUBECONFIG`.
Ensure to have a running `k3ces.localdomain` cluster running.

# Create cluster

- Init with `terraform init`
- Check plan with `terraform plan -var-file=secretVars.tfvars` or `terraform plan -var-file=secretVars.tfvars`
- Apply with `terraform apply -var-file=secretVars.tfvars` or `terraform apply -var-file=secretVars.tfvars`