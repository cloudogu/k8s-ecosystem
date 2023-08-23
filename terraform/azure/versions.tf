terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "2.10.1"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.65.0"
    }
    http = {
      source = "hashicorp/http"
      version = "3.4.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.5.1"
    }
  }

  required_version = ">= 0.14"
}