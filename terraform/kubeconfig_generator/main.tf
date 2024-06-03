terraform {
  required_providers {

  }
}

data "template_file" "kubeconfig" {
  template = file("${path.module}/kubeconfig.tpl")


  vars = {
    cluster_name           = var.cluster_name
    cluster_endpoint       = var.cluster_endpoint
    cluster_ca_certificate = var.cluster_ca_certificate
    access_token           = var.access_token
    client_key             = var.client_key
  }
}

resource "local_sensitive_file" "kubeconfig" {
  count    = var.kubeconfig_path != null ? 1 : 0
  content  = data.template_file.kubeconfig.rendered
  filename = var.kubeconfig_path
}