# -----------------------------------------------------------------------------
# SITA Stack - Prod Environment
# -----------------------------------------------------------------------------

locals {
  sita_base     = yamldecode(file("${path.root}/../../../stacks/sita/service.yaml"))
  sita_override = yamldecode(file("${path.root}/../../../stacks/sita/overrides/prod.yaml"))
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

  stack_name = "sita-prod"
  services   = local.sita_config.services
  networks   = local.sita_config.networks
  volumes    = local.sita_config.volumes
  secret_ids = {
    for name in local.sita_secret_names :
    name => data.external.sita_secrets[name].result.id
  }
}

# -----------------------------------------------------------------------------
# AOC Stack - Prod Environment
# -----------------------------------------------------------------------------

locals {
  aoc_base     = yamldecode(file("${path.root}/../../../stacks/aoc/service.yaml"))
  aoc_override = yamldecode(file("${path.root}/../../../stacks/aoc/overrides/prod.yaml"))
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

  stack_name = "aoc-prod"
  services   = local.aoc_config.services
  networks   = local.aoc_config.networks
  volumes    = local.aoc_config.volumes
  secret_ids = {
    for name in local.aoc_secret_names :
    name => data.external.aoc_secrets[name].result.id
  }
}

# -----------------------------------------------------------------------------
# MohjohFox Blog Stack - Prod Only
# -----------------------------------------------------------------------------

locals {
  blog_base     = yamldecode(file("${path.root}/../../../stacks/mohjohfox-blog/service.yaml"))
  blog_override = yamldecode(file("${path.root}/../../../stacks/mohjohfox-blog/overrides/prod.yaml"))
  blog_config = {
    services = {
      for k, v in local.blog_base.services :
      k => merge(v, lookup(local.blog_override.services, k, {}), {
        image   = merge(v.image, try(local.blog_override.services[k].image, {}))
        secrets = try(local.blog_override.services[k].secrets, try(v.secrets, []))
      })
    }
    networks = lookup(local.blog_base, "networks", {})
    volumes  = lookup(local.blog_base, "volumes", {})
  }

  # Collect all secret names used by blog services (currently none)
  blog_secret_names = distinct(flatten([
    for svc_name, svc in local.blog_config.services : [
      for secret in try(svc.secrets, []) :
      coalesce(try(secret.source, null), try(secret.name, null))
    ]
  ]))
}

# Lookup Blog secret IDs
data "external" "blog_secrets" {
  for_each = toset(local.blog_secret_names)

  program = ["bash", "${path.root}/../../scripts/get-secret-id.sh"]

  query = {
    name = each.value
  }
}

module "mohjohfox_blog" {
  source = "../../modules/swarm-stack"

  stack_name = "mohjohfox-blog"
  services   = local.blog_config.services
  networks   = local.blog_config.networks
  volumes    = local.blog_config.volumes
  secret_ids = {
    for name in local.blog_secret_names :
    name => data.external.blog_secrets[name].result.id
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

output "blog_services" {
  description = "MohjohFox Blog stack service names"
  value       = module.mohjohfox_blog.service_names
}
