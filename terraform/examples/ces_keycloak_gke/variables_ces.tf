variable "container_registry_secrets" {
  description = "A list of credentials for container registries used by dogus and components. The password must be base64 encoded. The regular configuration would contain registry.cloudogu.com as url."
  type        = list(object({
    url      = string
    username = string
    password = string
  }))
}
variable "dogu_registry_username" {
  description = "The username for the dogu-registry"
  type        = string
}

variable "dogu_registry_password" {
  description = "The base64-encoded password for the dogu-registry"
  type        = string
  sensitive   = true
}

variable "helm_registry_username" {
  description = "The username for the helm-registry"
  type        = string
}

variable "helm_registry_password" {
  description = "The base64-encoded password for the helm-registry"
  type        = string
  sensitive   = true
}

variable "ces_admin_username" {
  description = "The CES admin username"
  type        = string
  default     = "admin"
}

variable "ces_admin_password" {
  description = "The password for the ces admin user"
  type        = string
  sensitive   = true
}

variable "dogus" {
  description = "A list of Dogus to install, optional with version like official/cas:7.0.8-3"
  type        = list(string)
  default     = [
    "official/ldap",
    "official/postfix",
    "k8s/nginx-static",
    "k8s/nginx-ingress",
    "official/cas",
    "official/usermgt"
  ]
}

variable "component_operator_crd_chart" {
  description = "The helm chart of the component crd. Optional with version like k8s/k8s-component-operator-crd:1.2.1"
  type = string
  default = "k8s/k8s-component-operator-crd:latest"
}

variable "component_operator_chart" {
  description = "The helm chart of the component operator. Optional with version like k8s/k8s-component-operator:1.2.1"
  type = string
  default = "k8s/k8s-component-operator:latest"
}

variable "components" {
  description = "A list of components to install, optional with version like k8s/k8s-dogu-operator:3.0.1"
  type = list(string)
  default = [
    "k8s/k8s-dogu-operator",
    "k8s/k8s-dogu-operator-crd",
    "k8s/k8s-service-discovery",
  ]
}

variable "cas_oidc_optional" {
  description = <<EOT
  Specifies whether authentication via the configured OIDC provider is optional. The user will be automatically
  redirected to the OIDC provider login page if this property is set to 'false'. The 'true' entry makes authentication
  via the OIDC provider optional. This is done by displaying an additional button for the OIDC provider on the login
  page of the CAS, which can be used to authenticate with the OIDC provider.
  EOT
  type = bool
  default = false
}

variable "cas_oidc_allowed_groups" {
  description  = "Specifies cloudogu platform groups whose members can use the platform login. Only relevant if platform login is enabled."
  type         = list(string)
  default = []
}

variable "cas_oidc_initial_admin_usernames" {
  description  = "Specifies cloudogu platform usernames that are given admin rights in this CES. Only relevant if platform login is enabled."
  type         = list(string)
  default = []
}