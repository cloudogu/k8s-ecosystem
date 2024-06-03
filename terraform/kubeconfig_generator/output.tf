locals {
  kubeConfig = ""
}

output "kubeconfig_content" {
  value = data.template_file.kubeconfig
}