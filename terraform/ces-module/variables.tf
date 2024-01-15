variable "kubernetes_host" {
  description = "The hostname (in form of URI) of the Kubernetes API."
  type = string
}

variable "kubernetes_client_certificate" {
  description = "PEM-encoded client certificate for TLS authentication"
  type = string
}

variable "kubernetes_client_key" {
  description = "PEM-encoded client certificate key for TLS authentication"
  type = string
}

variable "kubernetes_cluster_ca_certificate" {
  description = "PEM-encoded root certificates bundle for TLS authentication"
  type = string
}

variable "setup_chart_version" {
  description = "The version of the k8s-ces-setup chart"
  type = string
  default = "0.20.2"
}

variable "setup_chart_namespace" {
  description = "The namespace of k8s-ces-setup chart"
  type = string
  default = "k8s"
}

variable "ces_namespace" {
  description = "The namespace for the CES"
  type = string
  default = "ecosystem"
}

variable "ces_admin_username" {
  description = "The CES admin username"
  type = string
  default = "admin"
}

variable "ces_admin_password" {
  description = "The CES admin password"
  type = string
}

variable "ces_admin_email" {
  description = "The CES admin email address"
  type = string
  default = "admin@admin.admin"
}

variable "ces_fqdn" {
  description = "Fully qualified domain name of the EcoSystem, e.g. 'www.ecosystem.my-domain.com'"
  type = string
}

variable "ces_certificate_path" {
  # Dev Cert:  openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/C=US/ST=Oregon/L=Portland/O=CompanyName/OU=DepartmentName/CN=example.com"
  description = "The certificate of the EcoSystem in PEM format. If null, a self-signed cert is created. If an intermediate certificate is used it also has to be entered here. The certificate chain has to be in the right order: The instance certificate first, intermediate certificate(s) second and at last the root certificate."
  type = string
  default = null
}

variable "ces_certificate_key_path" {
  description = " The certificate key of the EcoSystem in PEM format"
  type = string
  default = null
}

variable "default_dogu" {
  description = "The default Dogu of the EcoSystem"
  type    = string
  default = "cas"
}

variable "additional_dogus" {
  description = "A list of additional Dogus to install"
  type    = list(string)
  default = []
}

variable "image_registry_url" {
  description = "The url for the docker-image-registry"
  type = string
}

variable "image_registry_username" {
  description = "The username for the docker-image-registry"
  type = string
}

variable "image_registry_password" {
  description = "The password for the docker-image-registry"
  type = string
}

variable "image_registry_email" {
  description = "The email for the docker-image-registry"
  type = string
}

variable "dogu_registry_username" {
  description = "The username for the dogu-registry"
  type = string
}

variable "dogu_registry_password" {
  description = "The password for the dogu-registry"
  type = string
}

variable "dogu_registry_endpoint" {
  description = "The endpoint for the dogu-registry"
  type = string
}

variable "dogu_registry_url_schema" {
  description = "The URL schema for the dogu-registry ('default' or 'index')"
  type = string
  default = "default"
}

variable "helm_registry_host" {
  description = "The host for the helm-registry"
  type = string
}

variable "helm_registry_schema" {
  description = "The schema for the helm-registry"
  type = string
}

variable "helm_registry_plain_http" {
  description = "A flag which indicates if the component-operator should use plain http for the helm-registry"
  type = bool
  default = false
}

variable "helm_registry_insecure_tls" {
  description = "A flag which indicates if the component-operator should use insecure TLS for the helm-registry"
  type = bool
  default = false
}

variable "helm_registry_username" {
  description = "The username for the helm-registry"
  type = string
}

variable "helm_registry_password" {
  description = "The password for the helm-registry"
  type = string
}

variable "resource_patches_file" {
  description = "The location of a file containing resource-patches for the CES installation. The file-path is relative to the root-module-location"
  type = string
  default = null
}