locals {
  has_ces_fqdn = trimspace(var.ces_fqdn) != ""

  split_fqdn = split(".", var.ces_fqdn)
  # Top Level Domain extracted from fully qualified domain name. k3ces.local is used for development mode and empty fqdn.
  topLevelDomain = var.ces_fqdn != "" ? "${element(split(".", var.ces_fqdn), length(local.split_fqdn) - 2)}.${element(local.split_fqdn, length(local.split_fqdn) - 1)}" : "k3ces.local"

  globalConfig = concat(
    local.has_ces_fqdn ? [
      { key = "fqdn", value = var.ces_fqdn },
      { key = "domain", value = local.topLevelDomain }
    ] : [],

    # Always-present entries
    [
      { key = "certificate/type", value = var.ces_certificate_path == null ? "selfsigned" : "external" },
      # This must be added to secret: ecosystem-certificate
      #{ key = "certificate", value = var.ces_certificate_path != null ? replace(file(var.ces_certificate_path), "\n", "\\n") : ""},
      #{ key = "certificateKey", value = var.ces_certificate_key_path != null ? replace(file(var.ces_certificate_key_path), "\n", "\\n") : ""},

      # Password Policy
      {key  = "password-policy/min_length", value: "1"} ,
      { key = "password-policy/must_contain_capital_letter", value: "false"},
      { key = "password-policy/must_contain_digit", value: "false" },
      { key = "password-policy/must_contain_lower_case_letter", value = "false" },
      { key = "password-policy/must_contain_special_character", value: "false" },

      # Admin
      { key = "admin_group", value = "cesAdmin"},
    ],
  )
}

# The Blueprint is used to configure the system after the ecosystem-core has installed all
# necessary components, therefor it depends on the resource "ecosystem-core"
resource "kubectl_manifest" "blueprint" {
  yaml_body = templatefile(
    "${path.module}/blueprint.yaml.tftpl",
    {
      "dogus"         = local.parsedDogus
      "doguConfigs"   = local.doguConfigs
      "globalConfig"  = local.globalConfig
      "ces_namespace" = var.ces_namespace
    })
}