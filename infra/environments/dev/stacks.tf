# -----------------------------------------------------------------------------
# SITA Stack - Dev Environment
# -----------------------------------------------------------------------------

locals {
  sita_base     = yamldecode(file("${path.root}/../../../stacks/sita/service.yaml"))
  sita_override = yamldecode(file("${path.root}/../../../stacks/sita/overrides/dev.yaml"))
  sita_config = {
    services = {
      for k, v in local.sita_base.services :
      k => merge(v, lookup(local.sita_override.services, k, {}), {
        # Deep merge for nested objects like image and secrets
        image   = merge(v.image, try(local.sita_override.services[k].image, {}))
        secrets = try(local.sita_override.services[k].secrets, try(v.secrets, []))
      })
    }
    networks = lookup(local.sita_base, "networks", {})
    volumes  = lookup(local.sita_base, "volumes", {})
  }

  # Collect all secret names used by SITA services
  sita_secret_names = distinct(flatten([
    for svc_name, svc in local.sita_config.services : [
      for secret in try(svc.secrets, []) :
      coalesce(try(secret.source, null), try(secret.name, null))
    ]
  ]))
}

# Lookup SITA secret IDs
data "external" "sita_secrets" {
  for_each = toset(local.sita_secret_names)

  program = ["bash", "${path.root}/../../scripts/get-secret-id.sh"]

  query = {
    name = each.value
  }
}

module "sita" {
  source = "../../modules/swarm-stack"

  stack_name = "sita-dev"
  services   = local.sita_config.services
  networks   = local.sita_config.networks
  volumes    = local.sita_config.volumes
  secret_ids = {
    for name in local.sita_secret_names :
    name => data.external.sita_secrets[name].result.id
  }
}

# -----------------------------------------------------------------------------
# AOC Stack - Dev Environment
# -----------------------------------------------------------------------------

locals {
  aoc_base     = yamldecode(file("${path.root}/../../../stacks/aoc/service.yaml"))
  aoc_override = yamldecode(file("${path.root}/../../../stacks/aoc/overrides/dev.yaml"))
  aoc_config = {
    services = {
      for k, v in local.aoc_base.services :
      k => merge(v, lookup(local.aoc_override.services, k, {}), {
        image   = merge(v.image, try(local.aoc_override.services[k].image, {}))
        secrets = try(local.aoc_override.services[k].secrets, try(v.secrets, []))
      })
    }
    networks = lookup(local.aoc_base, "networks", {})
    volumes  = lookup(local.aoc_base, "volumes", {})
  }

  # Collect all secret names used by AOC services (currently none)
  aoc_secret_names = distinct(flatten([
    for svc_name, svc in local.aoc_config.services : [
      for secret in try(svc.secrets, []) :
      coalesce(try(secret.source, null), try(secret.name, null))
    ]
  ]))
}

# Lookup AOC secret IDs
data "external" "aoc_secrets" {
  for_each = toset(local.aoc_secret_names)

  program = ["bash", "${path.root}/../../scripts/get-secret-id.sh"]

  query = {
    name = each.value
  }
}

module "aoc" {
  source = "../../modules/swarm-stack"

  stack_name = "aoc-dev"
  services   = local.aoc_config.services
  networks   = local.aoc_config.networks
  volumes    = local.aoc_config.volumes
  secret_ids = {
    for name in local.aoc_secret_names :
    name => data.external.aoc_secrets[name].result.id
  }
}

# -----------------------------------------------------------------------------
# Stack Outputs
# -----------------------------------------------------------------------------

output "sita_services" {
  description = "SITA stack service names"
  value       = module.sita.service_names
}

output "aoc_services" {
  description = "AOC stack service names"
  value       = module.aoc.service_names
}
