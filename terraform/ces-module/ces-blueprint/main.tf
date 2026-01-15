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
      { key  = "password-policy/min_length", value: "1"} ,
      { key = "password-policy/must_contain_capital_letter", value: "false"},
      { key = "password-policy/must_contain_digit", value: "false" },
      { key = "password-policy/must_contain_lower_case_letter", value = "false" },
      { key = "password-policy/must_contain_special_character", value: "false" },

      # Admin
      { key = "admin_group", value = "cesAdmin"},
    ],
  )

  // generate blueprint from parameters
  generated_blueprint = yamldecode(templatefile(
    "${path.module}/blueprint.yaml.tftpl",
    {
      "dogus"         = local.parsedDogus
      "doguConfigs"   = local.doguConfigs
      "globalConfig"  = local.globalConfig
      "ces_namespace" = var.ces_namespace
    }))


  // patch passed blueprint
  passed_blueprint = try(yamldecode(var.blueprint), {})
  passed_blueprint_dogus = try(local.passed_blueprint.spec.blueprint.dogus, [])

  dogu_by_name = {
    for d in concat(local.passed_blueprint_dogus, local.parsedDogus) :
    d.name => d
  }

  merged_dogus = values(local.dogu_by_name)

  passed_blueprint_doguConfigs = try(local.passed_blueprint.spec.blueprint.config.dogus, {})
  merged_blueprint_doguConfigs = merge(local.passed_blueprint_doguConfigs, local.doguConfigs)

  passed_blueprint_globalConfig = try(local.passed_blueprint.spec.blueprint.config.global, [])
  merged_blueprint_globalConfig = concat(local.passed_blueprint_globalConfig, local.globalConfig)

  merged_blueprint_obj = merge(local.passed_blueprint, {
    metadata = merge(try(local.passed_blueprint.metadata, {}), {
      namespace = var.ces_namespace
    }) ,
    spec = merge(try(local.passed_blueprint.spec, {}), {
      blueprint = merge(try(local.passed_blueprint.spec.blueprint, {}), {
        dogus = local.merged_dogus,
        config = {
          dogus = local.merged_blueprint_doguConfigs,
          global = local.merged_blueprint_globalConfig
        }
      })
    })
  })

  merged_blueprint = trimspace(var.blueprint) == "" ? local.generated_blueprint : local.merged_blueprint_obj
}

output "blueprint_value" {
  value = var.blueprint
}

output "passed_blueprint_value" {
  value = yamlencode(local.passed_blueprint)
}

output "merged_blueprint_value" {
  value = yamlencode(local.merged_blueprint)
}

# The Blueprint is used to configure the system after the ecosystem-core has installed all
# necessary components, therefor it depends on the resource "ecosystem-core"
resource "kubectl_manifest" "blueprint" {
  yaml_body = yamlencode(local.merged_blueprint)
}