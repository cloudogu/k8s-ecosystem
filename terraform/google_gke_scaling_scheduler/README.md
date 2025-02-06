# Google-GKE-Scaling-Scheduler

This module can scale a node pool of a given cluster based on cronjobs. 
It can be used to shut down nodes at night or the weekend to save costs.

## Usage

Import this module in your terraform template like:

```terraform
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
      node_count      = var.node_count
      cron_expression = "0 4 * * 1-5"
    }
  ]
}
```