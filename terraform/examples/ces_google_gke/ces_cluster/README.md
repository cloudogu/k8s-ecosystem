# Usage

# Secret configuration (IAM - service account)

List available gcloud projects.

`gcloud projects list`

Set variables.

```bash
PROJECT_ID=<insert_your_project_name>
SERVICE_ACCOUNT_NAME=<insert_your_sa_name>
```

Ensure you are in the correct project.

`gcloud config set project $PROJECT_ID`

You need to create a service account for the google provider.

`gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME --description="DESCRIPTION" --display-name="$SERVICE_ACCOUNT_NAME" --project=$PROJECT_ID`

And assign the necessary Roles (only one role can be added each time with this command (see [here](https://www.googlecloudcommunity.com/gc/Developer-Tools/multiple-role-for-gcloud-iam-service-accounts-add-iam-policy/m-p/686863)))

`gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/editor"`
`gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/container.serviceAgent"`

Get that service account and save it to `secrets/gcp_sa.json`:

`gcloud iam service-accounts keys create secrets/gcp_sa.json --iam-account=$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com`

# General configuration
Use the `vars.tfvars.template` file to create `vars.tfvars` and set your GCP project and cluster name in it.

If you wish for example to create the cluster in another region you should template `vars.tfvars.template`.
See `variables.tf` for possibilities.

Use the `secretVars.tfvars.template` file to create `secretVars.tfvars` and set sensible information like passwords in it.

# Create cluster
Optional) If you want to save the state inside a google bucket look [here](../google_bucket/README.md). This is needed when multiple people want to be able to modify the same terraform resources.

Init with `terraform init`

> At this time the terraform plan and apply process has two stages because of the helm setup deployment.
> The cluster itself has to be created firstly to determine if the setup deployment is necessary.

Check plan
`terraform plan -var-file=secretVars.tfvars -var-file=vars.tfvars -target=module.google_gke`

Apply with
`terraform apply -var-file=secretVars.tfvars -var-file=vars.tfvars -target=module.google_gke`

This takes up to 15 minutes.

Create the remaining resources, including the CES setup
`terraform apply -var-file=secretVars.tfvars -var-file=vars.tfvars`

# Get kubeconfig

The module `kubeconfig_generator` will generate a `kubeconfig` in the example dir.

With gcloud you can get the config too:

- `gcloud container clusters get-credentials <cluster_name> --zone europe-west3-c --project $PROJECT_ID`

# Delete cluster

- `terraform destroy -var-file=secretVars.tfvars`
  or `terraform destroy -var-file=secretVars.tfvars -var-file=vars.tfvars`

# Backup configuration

## Disclaimer

Many configuration values are project wide. Make sure to change the corresponding names if necessary.


## Bucket configuration

### If you plan to use backup & restore with a google bucket, you need to create a separate service account first.

Create service account.

```bash
GSA_NAME=velero
gcloud iam service-accounts create --project $PROJECT_ID $GSA_NAME --display-name "Velero service account"
```

Get service account email.

`SERVICE_ACCOUNT_EMAIL=$(gcloud iam service-accounts list --project $PROJECT_ID --filter="displayName:Velero service account" --format 'value(email)')`

Add required google bucket and snapshot permissions to service account

```bash
ROLE_PERMISSIONS=(
    compute.disks.get
    compute.disks.create
    compute.disks.createSnapshot
    compute.projects.get
    compute.snapshots.get
    compute.snapshots.create
    compute.snapshots.useReadOnly
    compute.snapshots.delete
    compute.zones.get
    storage.objects.create
    storage.objects.delete
    storage.objects.get
    storage.objects.list
    iam.serviceAccounts.signBlob
)
```

`gcloud iam roles create velero.server --project $PROJECT_ID --title "Velero Server" --permissions "$(IFS=","; echo "${ROLE_PERMISSIONS[*]}")"`

`gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$SERVICE_ACCOUNT_EMAIL --role projects/$PROJECT_ID/roles/velero.server`

`gsutil iam ch serviceAccount:$SERVICE_ACCOUNT_EMAIL:objectAdmin gs://${BUCKET_NAME}`

## Configure ecosystem for backup & restore

Create the velero backup secret.

`kubectl create secret generic -n ecosystem velero-backup-target --from-file=cloud=secrets/gcp_sa.json`

Configure the ecosystem with backup & restore components.
It is recommended to apply a blueprint with all necessary components and configuration.
Check [example](example_cluster_resources/full_ces_blueprint_with_gcp_backup.yaml).
Configure section `backupStorageLocation` and `volumeSnapshotLocation` in `k8s-velero`.
If you do not use bucket encryption do not set the secret key in the velero configuration
