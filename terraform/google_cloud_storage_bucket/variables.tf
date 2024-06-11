variable "project" {
  type = string
}

variable "name" {
  description = "The name of the bucket"
  type        = string
  default     = "default"
}

variable "location" {
  description = "The location of the bucket. See: https://cloud.google.com/storage/docs/locations"
  type        = string
  default     = "EUROPE-WEST3"
}

variable "storage_class" {
  description = "The bucket's used storage class. See: https://cloud.google.com/storage/docs/storage-classes"
  type        = string
  default     = "COLDLINE"
}

variable "service_account_id" {
  type    = string
  default = "bucket-sa"
}

variable "service_account_display_name" {
  type    = string
  default = "bucket-sa-display-name"
}

variable "key_ring_name" {
  type    = string
  default = "bucket-keyring"
}

variable "key_name" {
  type    = string
  default = "bucket-key"
}

variable "key_rotation_period" {
  type    = string
  default = ""
}

variable "force_destroy" {
  type    = bool
  default = true
}

variable "key_purpose" {
  description = "See https://cloud.google.com/kms/docs/reference/rest/v1/projects.locations.keyRings.cryptoKeys#CryptoKeyPurpose"
  type        = string
  default     = "ENCRYPT_DECRYPT"
}

variable "use_encryption" {
  type    = bool
  default = true
}

#variable "service_account_email" {
#  type = string
#  description = "The e-mail from the used service account which calls the cloud storage api."
#}