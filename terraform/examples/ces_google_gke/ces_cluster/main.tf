locals {
  gke_module_host  = "https://${module.google_gke.endpoint}"
  gke_module_token = module.google_gke.access_token
  gke_module_ca_certificate = base64decode(module.google_gke.ca_certificate)

  kubernetes_version = "1.31"
  node_count         = 3

  helm_registry_schema       = "oci"
  helm_registry_host         = "registry.cloudogu.com"
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
  component_operator_crd_chart        = var.component_operator_crd_chart
  component_operator_image            = var.component_operator_image

  ces_fqdn                     = var.ces_fqdn
  ces_admin_username           = var.ces_admin_username
  ces_admin_password           = var.ces_admin_password

  dogus                        = var.dogus

  components = var.components

  # Configure access for the registries. Passwords need to be base64-encoded.
  dogu_registry_username     = var.dogu_registry_username
  dogu_registry_password     = var.dogu_registry_password

  docker_registry_email      = var.docker_registry_email
  docker_registry_host       = var.docker_registry_host
  docker_registry_password = var.dogu_registry_password
  docker_registry_username = var.docker_registry_username

  helm_registry_host         = local.helm_registry_host
  helm_registry_schema       = local.helm_registry_schema
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