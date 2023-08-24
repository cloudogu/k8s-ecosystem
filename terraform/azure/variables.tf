variable "azure_appId" {
  description = "Azure Kubernetes Service Cluster service principal"
}

variable "azure_password" {
  description = "Azure Kubernetes Service Cluster password"
}

variable "aks_cluster_name" {
  description = "The name of the Azure AKS Cluster"
}

variable "aks_node_count" {
  type = number
  description = "The number of nodes to create"
  default = 2
}

variable "aks_vm_size" {
  type = string
  description = "The size of the Virtual Machine fo the nodes, such as Standard_DS2_v2"
  default = "Standard_B2s"
}

variable "ecosystem_namespace" {
  description = "The namespace for the CES"
  default = "ecosystem"
}

variable "image_registry_url" {
  description = "The url for the docker-image-registry"
}

variable "image_registry_username" {
  description = "The username for the docker-image-registry"
}

variable "image_registry_password" {
  description = "The password for the docker-image-registry"
}

variable "image_registry_email" {
  description = "The email for the docker-image-registry"
}

variable "dogu_registry_username" {
  description = "The username for the dogu-registry"
}

variable "dogu_registry_password" {
  description = "The password for the dogu-registry"
}

variable "dogu_registry_endpoint" {
  description = "The endpoint for the dogu-registry"
}

variable "helm_registry_url" {
  description = "The url for the helm-registry"
}

variable "helm_registry_username" {
  description = "The username for the helm-registry"
}

variable "helm_registry_password" {
  description = "The password for the helm-registry"
}

variable "setup_chart_version" {
  description = "The version of the k8s-ces-setup chart"
}

variable "setup_chart_namespace" {
  description = "The namespace of k8s-ces-setup chart"
}

variable "ces_admin_password" {
  description = "The CES admin password"
}

variable "additional_dogus" {
  description = "A list of additional Dogus to install"
  type    = list(string)
  default = []
}