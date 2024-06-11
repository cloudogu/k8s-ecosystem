# Usage

Import this module in your terraform template like:

```terraform
module "increase_max_map_count" {
  depends_on = [module.google_gke] # Change this according your used cloud provider module
  source = "../../max-map-count"
}
```

If you want to run the daemonset only on a specific set on nodes you can specify a list of node selectors:

```terraform
module "increase_max_map_count" {
  depends_on = [module.google_gke] # Change this according your used cloud provider module
  source = "../../max-map-count"
  node_selectors = ["nodeType: db", "application: elasticsearch"]
}
```