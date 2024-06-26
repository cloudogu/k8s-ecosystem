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

`gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME --description="DESCRIPTION" --display-name="$SERVICE_ACCOUNT_NAME"`

And assign the necessary Roles

`gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/container.serviceAgent" --role="roles/editor"`

Get that service account and save it to `secrets/gcp_sa.json`:

`gcloud iam service-accounts keys create secrets/gcp_sa.json --iam-account=$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com`

# General configuration
Use the `vars.tfvars.template` file to create `vars.tfvars` and set your GCP project and cluster name in it.

If you wish for example to create the cluster in another region you should template `vars.tfvars.template`.
See `variables.tf` for possibilities.

# Create cluster

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

## Bucket configuration

### If you plan to use backup & restore with a google bucket, you need to create a separate service account first.

Create service account.

```bash
GSA_NAME=velero
gcloud iam service-accounts create $GSA_NAME --display-name "Velero service account"
```

Get service account email.

`SERVICE_ACCOUNT_EMAIL=$(gcloud iam service-accounts list --filter="displayName:Velero service account" --format 'value(email)')`

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

## If you want to use encryption the Cloud Storage Service Account needs permissions to access a keyring with a key.

Get the name of the service account.

`STORAGE_SA=$(curl https://storage.googleapis.com/storage/v1/projects/${PROJECT_ID}/serviceAccount --header "Authorization: Bearer $(gcloud auth print-access-token)" | jq '.email_address')`

Add role to access key. Keep in mind the location, keyring and key name. They have to be created later with terraform.
Defaults: `location=europe-west3, keyring=ces-keyring and key=ces-key`

`gcloud kms keys add-iam-policy-binding ces-key --location europe-west3 --keyring ces-keyring --member serviceAccount:$STORAGE_SA --role roles/cloudkms.cryptoKeyEncrypterDecrypter`

Get the name of the key.

`gcloud kms keys describe ces-key --location europe-west3 --keyring ces-keyring`

## Create bucket

Set terraform variable `create_backup_bucket`, `backup_bucket_name`, `use_bucket_encryption`, `key_ring_name`,
and `key_name`.

Reapply terraform.

## Configure ecosystem for backup & restore

Create the velero backup secret.

`kubectl create secret generic -n ecosystem velero-backup-target --from-file=cloud=secrets/gcp_sa.json`

Configure the ecosystem with backup & restore components.
It is recommended to apply a blueprint with all necessary components and configuration.
Check [example](example/full_ces_blueprint_with_gcp_backup.yaml).
Configure section `backupStorageLocation` and `volumeSnapshotLocation` in `k8s-velero`.
If you do not use bucket encryption do not set the secret key in the velero configuration
