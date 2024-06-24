## Create bucket

Set terraform variable `create_bucket` and `bucket_name`. If you wish to encrypt your bucket set `use_bucket_encryption`,
`key_ring_name` and `key_name`, too.

If you want to use encryption do [this](#bucket-encryption) first.

(Optional) If you want to save the state inside a google bucket look [here](#terraform-state-bucket-setup)

Init with `terraform init`


Check plan
`terraform plan -var-file=secretVars.tfvars -var-file=vars.tfvars`

Apply with
`terraform apply -var-file=secretVars.tfvars -var-file=vars.tfvars`

### Bucket Encryption

Get the name of the service account.

`STORAGE_SA=$(curl https://storage.googleapis.com/storage/v1/projects/${PROJECT_ID}/serviceAccount --header "Authorization: Bearer $(gcloud auth print-access-token)" | jq -r '.email_address')`

Add role to access key. Keep in mind the location, keyring and key name. They have to be created later with terraform.
Defaults: `location=europe-west3, keyring=ces-keyring and key=ces-key`

`gcloud kms keys add-iam-policy-binding ces-key --project ${PROJECT_ID} --location europe-west3 --keyring ces-key-ring --member serviceAccount:$STORAGE_SA --role roles/cloudkms.cryptoKeyEncrypterDecrypter`

Get the name of the key.

`gcloud kms keys describe ces-key --project ${PROJECT_ID} --location europe-west3 --keyring ces-key-ring`

## Terraform state bucket setup

### Check if the bucket already exists

Set the current project (optional)

```bash
gcloud config set project <YOUR_PROJECT_ID>
```

Check if the bucket exists

```bash
gsutil ls | grep "<YOUR_TERRAFORM_STATE_BUCKET_NAME>"
```

If the bucket already exists, the bucket only needs to be defined as the storage location for the terraform state.

### Create the bucket

Update the variables to define the name for your terraform state bucket.
create_backup_bucket has to be true.
After that you can initialize and apply terraform

```bash
terraform init
terraform plan -var-file=vars.tfvars -var-file=secretVars.tfvars
terraform apply -var-file=vars.tfvars -var-file=secretVars.tfvars
```

### Define the bucket as the storage location

Add this block to your main.tf

```terraform
terraform {
 backend "gcs" {}
}
```

And add a file named *.gcs.tfbackend with the following content.

```
bucket  = "YOUR_BUCKET_NAME"
prefix  = "STATE_PATH"
credentials = "YOUR_CREDENTIALS_JSON"
```