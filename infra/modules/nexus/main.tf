terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Nexus Docker Image
# -----------------------------------------------------------------------------
resource "docker_image" "nexus" {
  name         = "sonatype/nexus3:${var.nexus_version}"
  keep_locally = true
}

# -----------------------------------------------------------------------------
# Stack Network
# -----------------------------------------------------------------------------
resource "docker_network" "nexus" {
  name   = "${var.stack_name}_nexus"
  driver = "overlay"

  labels {
    label = "com.docker.stack.namespace"
    value = var.stack_name
  }
}

# -----------------------------------------------------------------------------
# Nexus Data Volume
# -----------------------------------------------------------------------------
resource "docker_volume" "nexus_data" {
  name = "${var.stack_name}_nexus-data"

  labels {
    label = "com.docker.stack.namespace"
    value = var.stack_name
  }
}

# -----------------------------------------------------------------------------
# Nexus Swarm Service
# -----------------------------------------------------------------------------
resource "docker_service" "nexus" {
  name = "${var.stack_name}_nexus"

  labels {
    label = "com.docker.stack.namespace"
    value = var.stack_name
  }

  task_spec {
    container_spec {
      image = docker_image.nexus.name

      env = {
        INSTALL4J_ADD_VM_PARAMS = "-Xms${var.nexus_jvm_heap_size} -Xmx${var.nexus_jvm_heap_size} -XX:MaxDirectMemorySize=${var.nexus_jvm_max_direct_memory}"
      }

      mounts {
        target = "/nexus-data"
        source = docker_volume.nexus_data.name
        type   = "volume"
      }

      healthcheck {
        test     = ["CMD", "curl", "-f", "http://localhost:8081/service/metrics/healthcheck"]
        interval = "30s"
        timeout  = "10s"
        retries  = 3
      }
    }

    resources {
      limits {
        memory_bytes = var.nexus_memory_limit * 1024 * 1024
      }
      reservation {
        memory_bytes = var.nexus_memory_reservation * 1024 * 1024
      }
    }

    restart_policy {
      condition = "on-failure"
      delay     = "5s"
      window    = "120s"
    }

    networks_advanced {
      name = docker_network.nexus.id
    }
  }

  endpoint_spec {
    ports {
      target_port    = 8081
      published_port = var.nexus_port
      protocol       = "tcp"
      publish_mode   = "ingress"
    }
  }

  update_config {
    parallelism = 1
    order       = "stop-first"
    delay       = "10s"
  }

  rollback_config {
    parallelism = 1
    order       = "stop-first"
    delay       = "10s"
  }

  mode {
    replicated {
      replicas = var.nexus_replicas
    }
  }
}
