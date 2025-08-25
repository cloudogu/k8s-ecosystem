locals {
  gke_module_host  = "https://${module.google_gke.endpoint}"
  gke_module_token = module.google_gke.access_token
  gke_module_ca_certificate = base64decode(module.google_gke.ca_certificate)

  kubernetes_version = "1.31"
  node_count         = 3

  dogu_registry_url_schema = "default"
  dogu_registry_endpoint   = "https://dogu.cloudogu.com/api/v2/dogus"

  helm_registry_schema       = "oci"
  helm_registry_host         = "registry.cloudogu.com"
  helm_registry_plain_http   = false
  helm_registry_insecure_tls = false

  setup_chart_namespace = "k8s"
  setup_chart_version   = "4.1.1"

  resource_patches_file = "resource_patches.yaml"
}

module "kubeconfig_generator" {
  source                 = "../../../kubeconfig_generator"
  cluster_name           = var.cluster_name
  access_token           = module.google_gke.access_token
  cluster_ca_certificate = module.google_gke.ca_certificate
  cluster_endpoint       = "https://${module.google_gke.endpoint}"

  kubeconfig_path = "kubeconfig"
}

module "google_gke" {
  source             = "../../../google_gke"
  cluster_name       = var.cluster_name
  kubernetes_version = local.kubernetes_version
  idp_enabled        = false

  node_pool_name = var.node_pool_name
  machine_type   = var.machine_type
  node_count     = local.node_count
}

module "increase_max_map_count" {
  depends_on = [module.google_gke]
  source = "../../../max-map-count"
}

module "ces" {
  depends_on = [module.google_gke]
  source = "../../../ces-module"

  # Configure CES installation options
  setup_chart_version          = local.setup_chart_version
  setup_chart_namespace        = local.setup_chart_namespace
  ces_fqdn                     = var.ces_fqdn
  ces_admin_username           = var.ces_admin_username
  ces_admin_password           = var.ces_admin_password
  dogus                        = var.dogus
  resource_patches = file(local.resource_patches_file)
  component_operator_chart     = var.component_operator_chart
  component_operator_crd_chart = var.component_operator_crd_chart
  components = var.components

  # Configure access for the registries. Passwords need to be base64-encoded.
  container_registry_secrets = var.container_registry_secrets
  dogu_registry_username     = var.dogu_registry_username
  dogu_registry_password     = var.dogu_registry_password
  dogu_registry_endpoint     = local.dogu_registry_endpoint
  dogu_registry_url_schema   = local.dogu_registry_url_schema

  helm_registry_host         = local.helm_registry_host
  helm_registry_schema       = local.helm_registry_schema
  helm_registry_plain_http   = local.helm_registry_plain_http
  helm_registry_insecure_tls = local.helm_registry_insecure_tls
  helm_registry_username     = var.helm_registry_username
  helm_registry_password     = var.helm_registry_password
}

module "scale_jobs" {
  depends_on = [module.google_gke]
  source                = "../../../google_gke_scaling_scheduler"
  project_id            = var.gcp_project_name
  cluster_location      = var.gcp_zone
  scheduler_region      = var.gcp_region
  cluster_name          = var.cluster_name
  node_pool_name        = var.node_pool_name
  service_account_email = jsondecode(file(var.gcp_credentials)).client_email
  scale_jobs = [
    {
      node_count      = 0
      cron_expression = "0 18 * * *"
    },
    {
      node_count      = local.node_count
      cron_expression = "0 4 * * 1-5"
    }
  ]
}