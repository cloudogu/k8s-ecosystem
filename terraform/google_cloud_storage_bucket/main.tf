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
    prevent_destroy = true
  }
}

# Remove non encrypted default storage class
resource "kubernetes_annotations" "default-storageclass" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  force       = "true"

  metadata {
    name = "standard-rwo"
  }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "false"
  }
}

resource "kubernetes_storage_class" "standard-rwo-encrypted" {
  count    = var.use_encryption ? 1 : 0
  metadata {
    annotations = {
      "components.gke.io/component-name" = "pdcsi"
      "components.gke.io/layer" = "addon"
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
    labels = {
      "addonmanager.kubernetes.io/mode" =  "EnsureExists"
      "k8s-app" = "gcp-compute-persistent-disk-csi-driver"
    }

    name = "standard-rwo-encrypted"
  }

  storage_provisioner = "pd.csi.storage.gke.io"
  reclaim_policy = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"
  allow_volume_expansion = true
  parameters = {
    type = "pd-balanced"
    disk-encryption-kms-key = "projects/ces-coder-workspaces/locations/europe-west3/keyRings/ces-key-ring-47171-1/cryptoKeys/ces-key"
  }
}
