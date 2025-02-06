variable "gardener_kube_config_path" {
  description = "The kube config to the gardener cluster"
  type        = string
  default     = "gardener_kubeconfig.yaml"
}

variable garden_namespace {
  description = "The namespace for the shoot resource. See kubeconfig."
  type = string
}

variable "secret_binding_name" {
  description = "Secret binding. Depends on the selected cloud profile. See https://dashboard.prod.gardener.get-cloud.io/namespace/<your garden>/secrets"
  type = string
}

variable "project_id" {
  description = "Project ID from PSKE"
  type = string
}

variable "networking_type" {
  type = string
  // We use calico instead of cilium (PSKE default) because cilium needs more network policies in the auth process
  // between cas and the dogus. Without a networkpolicy which allows the dogu to reach the nginx-ingress the redirect flow stucks.
  // With calico or flannel (not supported in PSKE) it works without the extra network policy.
  default = "calico"
}