terraform {
  required_version = ">= 1.5.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    kubectl = {
      // The official kubectl provider from hashicorp can't be used because it requires crd read permissions on generic cr apply.
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    http = {
      source = "hashicorp/http"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}