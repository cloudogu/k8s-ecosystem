variable "private_registries" {
  description = "A list of private container-registries. Each entry must habe an 'url', an 'username' and a 'password' (base64-encoded)"
  type = list(object({
    url = string
    username = string
    password = string
  }))
  sensitive   = true
}