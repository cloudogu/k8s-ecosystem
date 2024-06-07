resource "random_id" "bucket_prefix" {
  byte_length = 8
}

resource "google_storage_bucket" "bucket" {
  name          = "${var.name}-${random_id.bucket_prefix.hex}"
  project       = var.project
  location      = var.location
  storage_class = var.storage_class
  force_destroy = var.force_destroy

  encryption {
    default_kms_key_name = var.use_encryption ? google_kms_crypto_key.bucket_key[0].id : ""
  }

  uniform_bucket_level_access = true
}

resource "google_kms_key_ring" "bucket_keyring" {
  count    = var.use_encryption ? 1 : 0
  name     = var.key_ring_name
  location = var.location
  project  = var.project
}

resource "google_kms_crypto_key" "bucket_key" {
  depends_on      = [google_kms_key_ring.bucket_keyring]
  count           = var.use_encryption ? 1 : 0
  name            = var.key_name
  key_ring        = google_kms_key_ring.bucket_keyring[0].id
  rotation_period = var.key_rotation_period

  purpose = var.key_purpose

  lifecycle {
    prevent_destroy = false # TODO Change this to true
  }
}

#data "google_storage_project_service_account" "gcs_account" {
#
#}

// Crypto IAM binding to use recent key ring and key
#resource "google_kms_crypto_key_iam_binding" "key_binding" {
#  crypto_key_id = google_kms_crypto_key.bucket_key[0].id
#  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
#
#  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
#}
