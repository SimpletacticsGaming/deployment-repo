terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------

locals {
  # Flatten all external networks for data source lookup
  external_networks = [
    for net_name, net in var.networks : net_name
    if lookup(net, "external", false)
  ]
}

# -----------------------------------------------------------------------------
# External Networks (data sources)
# -----------------------------------------------------------------------------

data "docker_network" "external" {
  for_each = toset(local.external_networks)
  name     = each.value
}

# -----------------------------------------------------------------------------
# Stack Volumes
# -----------------------------------------------------------------------------

resource "docker_volume" "stack" {
  for_each = var.volumes

  name   = "${var.stack_name}_${each.key}"
  driver = each.value.driver

  labels {
    label = "com.docker.stack.namespace"
    value = var.stack_name
  }
}

# -----------------------------------------------------------------------------
# Docker Swarm Services
# -----------------------------------------------------------------------------

resource "docker_service" "service" {
  for_each = var.services

  name = "${var.stack_name}_${each.key}"

  labels {
    label = "com.docker.stack.namespace"
    value = var.stack_name
  }

  task_spec {
    container_spec {
      image = "${each.value.image.repository}:${each.value.image.tag}"

      # Environment variables
      env = {
        for env_var in coalesce(each.value.environment, []) :
        env_var.name => env_var.value
      }

      # Secrets - reference by name, Swarm will resolve them
      dynamic "secrets" {
        for_each = coalesce(each.value.secrets, [])
        content {
          secret_id   = var.secret_ids[coalesce(secrets.value.source, secrets.value.name)]
          secret_name = coalesce(secrets.value.source, secrets.value.name)
          file_name   = "/run/secrets/${coalesce(secrets.value.target, coalesce(secrets.value.source, secrets.value.name))}"
          file_mode   = parseint(coalesce(secrets.value.mode, "0444"), 8)
        }
      }

      # Healthcheck
      dynamic "healthcheck" {
        for_each = each.value.healthcheck != null ? [each.value.healthcheck] : []
        content {
          test     = healthcheck.value.test
          interval = healthcheck.value.interval
          timeout  = healthcheck.value.timeout
          retries  = healthcheck.value.retries
        }
      }
    }

    # Resources
    resources {
      dynamic "limits" {
        for_each = try(each.value.resources.limits, null) != null ? [each.value.resources.limits] : []
        content {
          nano_cpus = limits.value.cpu != null ? parseint(replace(limits.value.cpu, ".", ""), 10) * 10000000 : null
          memory_bytes = limits.value.memory != null ? (
            endswith(limits.value.memory, "G") ? parseint(trimsuffix(limits.value.memory, "G"), 10) * 1024 * 1024 * 1024 :
            endswith(limits.value.memory, "M") ? parseint(trimsuffix(limits.value.memory, "M"), 10) * 1024 * 1024 :
            parseint(limits.value.memory, 10)
          ) : null
        }
      }

      dynamic "reservation" {
        for_each = try(each.value.resources.reservations, null) != null ? [each.value.resources.reservations] : []
        content {
          nano_cpus = reservation.value.cpu != null ? parseint(replace(reservation.value.cpu, ".", ""), 10) * 10000000 : null
          memory_bytes = reservation.value.memory != null ? (
            endswith(reservation.value.memory, "G") ? parseint(trimsuffix(reservation.value.memory, "G"), 10) * 1024 * 1024 * 1024 :
            endswith(reservation.value.memory, "M") ? parseint(trimsuffix(reservation.value.memory, "M"), 10) * 1024 * 1024 :
            parseint(reservation.value.memory, 10)
          ) : null
        }
      }
    }

    # Restart policy
    restart_policy {
      condition = try(each.value.restart.condition, "on-failure")
      delay     = try(each.value.restart.delay, "5s")
      window    = "120s"
    }

    # Networks
    dynamic "networks_advanced" {
      for_each = coalesce(each.value.networks, [])
      content {
        name = contains(local.external_networks, networks_advanced.value) ? data.docker_network.external[networks_advanced.value].id : networks_advanced.value
      }
    }
  }

  # Update config
  update_config {
    parallelism = try(each.value.update.parallelism, 1)
    order       = try(each.value.update.order, "stop-first")
    delay       = try(each.value.update.delay, "10s")
  }

  # Rollback config
  rollback_config {
    parallelism = 1
    order       = "stop-first"
    delay       = "10s"
  }

  # Mode (replicas)
  mode {
    replicated {
      replicas = each.value.replicas
    }
  }

  # Converge config for waiting
  converge_config {
    delay   = "7s"
    timeout = "3m"
  }
}
