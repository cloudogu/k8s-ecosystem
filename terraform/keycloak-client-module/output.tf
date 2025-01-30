output "external_cas_openid_client_id" {
  value = local.external_cas_openid_client_id
}

output "external_cas_openid_client_secret" {
  value = random_password.external_cas_openid_client_secret.result
  sensitive = true
}