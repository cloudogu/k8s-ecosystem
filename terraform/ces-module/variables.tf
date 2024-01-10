variable "kubernetes_host" {
  description = "The hostname (in form of URI) of the Kubernetes API."
}

variable "kubernetes_client_certificate" {
  description = "PEM-encoded client certificate for TLS authentication"
}

variable "kubernetes_client_key" {
  description = "PEM-encoded client certificate key for TLS authentication"
}

variable "kubernetes_cluster_ca_certificate" {
  description = "PEM-encoded root certificates bundle for TLS authentication"
}

variable "setup_chart_version" {
  description = "The version of the k8s-ces-setup chart"
  default = "0.20.2"
}

variable "setup_chart_namespace" {
  description = "The namespace of k8s-ces-setup chart"
  default = "k8s"
}

variable "ces_namespace" {
  description = "The namespace for the CES"
  default = "ecosystem"
}

variable "ces_admin_password" {
  description = "The CES admin password"
}

variable "ces_fqdn" {
  description = "Fully qualified domain name of the EcoSystem, e.g. 'www.ecosystem.my-domain.com'"
}

variable "ces_certificate_path" {
  # Dev Cert:  openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/C=US/ST=Oregon/L=Portland/O=CompanyName/OU=DepartmentName/CN=example.com"
  description = "The certificate of the EcoSystem in PEM format. If null, a self-signed cert is created. If an intermediate certificate is used it also has to be entered here. The certificate chain has to be in the right order: The instance certificate first, intermediate certificate(s) second and at last the root certificate."
  default = null
}

variable "ces_certificate_key_path" {
  description = " The certificate key of the EcoSystem in PEM format"
  default = null
}

variable "additional_dogus" {
  description = "A list of additional Dogus to install"
  type    = list(string)
  default = []
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

variable "helm_registry_host" {
  description = "The host for the helm-registry"
}

variable "helm_registry_schema" {
  description = "The schema for the helm-registry"
}

variable "helm_registry_plain_http" {
  description = "A flag which indicates if the component-operator should use plain http"
}

variable "helm_registry_username" {
  description = "The username for the helm-registry"
}

variable "helm_registry_password" {
  description = "The password for the helm-registry"
}