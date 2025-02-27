terraform {
  required_version = ">= 0.14"

  required_providers {
    kubectl = {
      // The official kubectl provider from hashicorp can't be used because it requires crd read permissions on generic cr apply.
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}
