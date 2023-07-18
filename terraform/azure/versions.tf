terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.22.0"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.65.0"
    }
    http = {
      source = "hashicorp/http"
      version = "3.4.0"
    }
  }

  required_version = ">= 0.14"
}