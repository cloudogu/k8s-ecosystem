# CES Keycloak GKE example

This is an example how to use the keycloak client module to configure delegated authentication
in a Cloudogu EcoSystem running on the Google Kubernetes Engine.

## Usage

### Secret configuration (IAM - service account)

List available gcloud projects.

`gcloud projects list`

Set variables.

```bash
PROJECT_ID=<insert_your_project_name>
SERVICE_ACCOUNT_NAME=<insert_your_sa_name>
```

Ensure you are in the correct project.

`gcloud config set project $PROJECT_ID`

You need to create a service account for the Google provider.

`gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME --description="DESCRIPTION" --display-name="$SERVICE_ACCOUNT_NAME" --project=$PROJECT_ID`

And assign the necessary Roles (only one role can be added each time with this command (see [here](https://www.googlecloudcommunity.com/gc/Developer-Tools/multiple-role-for-gcloud-iam-service-accounts-add-iam-policy/m-p/686863)))

`gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/editor"`
`gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/container.serviceAgent"`

Get that service account and save it to `secrets/gcp_sa.json`:

`gcloud iam service-accounts keys create secrets/gcp_sa.json --iam-account=$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com`

### General configuration
Use the `terraform.tfvars.template` file to create `terraform.tfvars` and set your GCP project and cluster name in it.

If you wish for example to create the cluster in another region you should template `terraform.tfvars.template`.
See `variables.tf` for possibilities.

Use the `secretVars.tfvars.template` file to create `secretVars.tfvars` and set sensitive information like passwords in it.

If you wish to know more about how to use the keycloak-module, have a look at its [Readme](../../keycloak-client-module).

### Create cluster

Init with `terraform init -upgrade`

Check plan
`terraform plan -var-file=secretVars.tfvars`

Apply with
`terraform apply -var-file=secretVars.tfvars`

This takes up to 15 minutes.

### Get kubeconfig

```
gcloud container clusters get-credentials <cluster_name> --zone europe-west3-c --project $PROJECT_ID
```

### Delete cluster

```
terraform destroy -var-file=secretVars.tfvars
```
