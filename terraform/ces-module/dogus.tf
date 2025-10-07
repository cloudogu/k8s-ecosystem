locals {
  dogu_items = [
    for s in var.dogus : {
      name    = split(":", s)[0]
      version = length(split(":", s)) == 2 ? split(":", s)[1] : null
    }
  ]

  # collect dogus with latest tag
  dogus_needing_latest = toset([
    for d in local.dogu_items : d.name
    if (d.version == null || lower(d.version) == "latest")
  ])

  # get version by name
  latest_by_name = {
    for name, resp in data.http.dogu_versions :
    name => (
      resp.status_code == 200 ? try(jsondecode(resp.response_body)[0], null) : resp.body
    )
  }

  parsedDogus = [
    for d in local.dogu_items : {
      name    = d.name
      version = (d.version == null || lower(d.version) == "latest" ) ? coalesce(lookup(local.latest_by_name, d.name, null), "latest") : d.version
    }
  ]

  doguConfigs = {
    ldap = [
      { key = "admin_username", value = var.ces_admin_username },
      { key = "admin_mail", value = var.ces_admin_email },
      { key = "admin_member", value = "true" },

      { key: "admin_password", secretRef:  { key: "ldap_admin_password", name: "ecosystem-core-setup-credentials" }, sensitive: true}
    ],
    postfix = [
      { key = "relayhost", value = "foobar" }
    ],
    cas = [
      { key = "oidc/enabled", value = var.cas_oidc_config.enabled },
      { key = "oidc/discovery_uri", value = var.cas_oidc_config.discovery_uri },
      { key = "oidc/client_id", value = var.cas_oidc_config.client_id },
      { key = "oidc/display_name", value = var.cas_oidc_config.display_name },
      { key = "oidc/optional", value = tostring(var.cas_oidc_config.optional) },
      { key = "oidc/scopes", value = join(",", var.cas_oidc_config.scopes) },
      { key = "oidc/principal_attribute", value = var.cas_oidc_config.principal_attribute },
      { key = "oidc/attribute_mapping", value = var.cas_oidc_config.attribute_mapping },
      { key = "oidc/allowed_groups", value = join(",", var.cas_oidc_config.allowed_groups) },
      { key = "oidc/initial_admin_usernames", value = join(",", var.cas_oidc_config.initial_admin_usernames) },

      { key: "oidc/client_secret", secretRef:  { key: "cas_oidc_client_secret", name: "ecosystem-core-setup-credentials" }, sensitive: true}
    ]
  }
}


# get version by calling registry list
data "http" "dogu_versions" {
  for_each = local.dogus_needing_latest
  url      = "https://dogu.cloudogu.com/api/v2/dogus/${each.key}/_versions"

  request_headers = {
    Authorization = "Basic ${local.dogu_auth_b64}"
    Accept        = "application/json"
    User-Agent    = "terraform"
  }
}