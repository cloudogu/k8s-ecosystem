variable "gardener_kube_config_path" {
  description = "The path to the kube config for the gardener cluster."
  type = string
  default = "./gardener_kubeconfig.yaml"
}

#variable shoot_name {
#  description = "The name of the shoot cluster"
#  type = string
#  default = ""
#}

variable garden_namespace {
  description = "The namespace for the shoot resource. See kubeconfig."
  type = string
}

variable shoot_name_prefix {
  description = "The prefix name of the shoot resource. It will be concatenated with a uuid"
  type = string
  default = "ces-"
}

variable hibernation {
  description= "Specifies if the cluster should be hibernated or not"
  type = bool
  default = false
}

variable hibernation_schedules {
  description = "Hibernation rules. Set an empty List to disable hibernation."
  type = list(object({
    end: string
    location: string
    start: string
  }))
  default = [
    {
      "end"      = "00 06 * * 1,2,3,4,5"
      "location" = "Europe/Berlin"
      "start"    = "00 19 * * 1,2,3,4,5"
    },
  ]
}

variable "kubernetes_version" {
  type = string
  default = "1.30.7"
}

variable "networking_type" {
  type = string
  default = "cilium"
}

variable "purpose" {
  description = "Plusserver purpose. Valid values are evaluation, development, testing and production"
  type = string
  default = "evaluation"
}

variable cloud_profile_name {
  description = "Use cloud profile"
  type = string
  default = "pluscloudopen"
}

variable "region" {
  description = "Region of the cluster. Depends on the selected cloud profile"
  type = string
  default = "prod1"
}

variable "secret_binding_name" {
  description = "Secret binding. Depends on the selected cloud profile. See https://dashboard.prod.gardener.get-cloud.io/namespace/<your garden>/secrets"
  type = string
}

variable "project_id" {
  description = "Project ID from PSKE"
  type = string
}

variable "image_name" {
  type = string
  default = "flatcar"
}

variable "image_version" {
  type = string
  default = "3975.2.2"
}

variable "machine_type" {
  type = string
  default = "SCS-4V-8"
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

variable "node_size" {
  type = string
  default = "50Gi"
}

variable cluster_removable {
  description = "Indicates if the cluster can be removed with terraform destroy command"
  type = string
  default = "true"
}