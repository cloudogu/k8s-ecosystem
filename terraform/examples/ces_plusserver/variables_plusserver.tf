variable "gardener_kube_config_path" {
  description = "The kube config to the gardener cluster"
  type        = string
  default     = "gardener_kubeconfig.yaml"
}

#variable shoot_name {
#  description = "The name of the shoot cluster"
#  type = string
#}

variable garden_namespace {
  description = "The namespace for the shoot resource. See kubeconfig."
  type = string
}

variable gardener_identity {
  description = "The identity from the gardener: KUBECONFIG=gardener.yaml kubectl -n kube-system get configmap cluster-identity -o jsonpath='{.data.cluster-identity}'"
  type = string
  default = "gardener-prod"
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

variable "max_surge" {
  description = "Maximum node surge"
  type = number
  default = 1
}

variable "node_min" {
  description = "Minimum node count"
  type = number
  default = 3
}

variable "node_max" {
  description = "Maximum node count"
  type = number
  default = 4
}

variable hibernation {
  description= "Specifies if the cluster should be hibernated or not"
  type = bool
  default = false
}

variable gardenctl_source {
  description = "The source of gardenctl which is downloaded during apply."
  type = string
  default = "https://github.com/gardener/gardenctl-v2/releases/download/v2.10.0/gardenctl_v2_linux_amd64"
}

variable gardenctl_sha256 {
  description = "SHA256 sum of the gardenctl binary"
  type = string
  default = "87b2c35c828c3d2b40ff02ddf5eae7f6c92e3d2ec8016249d2b122a6a73a43cb"
}

variable gardenlogin_source {
  description = "The source of gardenlogin which is downloaded during apply."
  type = string
  default = "https://github.com/gardener/gardenlogin/releases/download/v0.6.0/gardenlogin_linux_amd64"
}

variable gardenlogin_sha256 {
  description = "SHA256 sum of the gardenlogin binary"
  type = string
  default = "87894a729675dcedadc241be6ad52e0244e70000b180516c5d9198e0f726b9d7"
}