
output "ca_certificate" {
  value = google_container_cluster.default.master_auth[0].cluster_ca_certificate
  sensitive = true
}

output "endpoint" {
  value = google_container_cluster.default.endpoint
}

output "access_token" {
  value = data.google_client_config.default.access_token
}