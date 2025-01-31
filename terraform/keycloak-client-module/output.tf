output "client_secret" {
  value = random_password.client_secret.result
  sensitive = true
}