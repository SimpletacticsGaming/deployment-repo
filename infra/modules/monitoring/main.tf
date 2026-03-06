terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------
resource "docker_network" "monitoring" {
  name   = var.monitoring_network_name
  driver = "bridge"
}

# -----------------------------------------------------------------------------
# Grafana
# -----------------------------------------------------------------------------
resource "docker_image" "grafana" {
  name         = "grafana/grafana:${var.grafana_version}"
  keep_locally = true
}

resource "docker_volume" "grafana_data" {
  name = "grafana_data"
}

resource "docker_container" "grafana" {
  name  = "grafana"
  image = docker_image.grafana.image_id

  restart = "unless-stopped"

  ports {
    internal = 3000
    external = var.grafana_port
  }

  env = [
    "GF_SECURITY_ADMIN_USER=${var.grafana_admin_user}",
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
    "GF_USERS_ALLOW_SIGN_UP=false",
  ]

  volumes {
    volume_name    = docker_volume.grafana_data.name
    container_path = "/var/lib/grafana"
  }

  upload {
    content = file("${path.module}/configs/grafana/provisioning/datasources/datasources.yaml")
    file    = "/etc/grafana/provisioning/datasources/datasources.yaml"
  }

  networks_advanced {
    name = docker_network.monitoring.id
  }

  memory = var.grafana_memory_limit

  depends_on = [
    docker_container.loki,
    docker_container.prometheus,
  ]
}

# -----------------------------------------------------------------------------
# Loki
# -----------------------------------------------------------------------------
resource "docker_image" "loki" {
  name         = "grafana/loki:${var.loki_version}"
  keep_locally = true
}

resource "docker_volume" "loki_data" {
  name = "loki_data"
}

resource "docker_container" "loki" {
  name  = "loki"
  image = docker_image.loki.image_id

  restart = "unless-stopped"

  ports {
    internal = 3100
    external = 3100
  }

  volumes {
    volume_name    = docker_volume.loki_data.name
    container_path = "/loki"
  }

  upload {
    file    = "/etc/loki/local-config.yaml"
    content = templatefile("${path.module}/configs/loki/loki-config.yaml", {
      retention_period = var.loki_retention_period
    })
  }

  command = ["-config.file=/etc/loki/local-config.yaml"]

  memory = var.loki_memory_limit

  networks_advanced {
    name = docker_network.monitoring.id
  }
}

# -----------------------------------------------------------------------------
# Prometheus
# -----------------------------------------------------------------------------
resource "docker_image" "prometheus" {
  name         = "prom/prometheus:v${var.prometheus_version}"
  keep_locally = true
}

resource "docker_volume" "prometheus_data" {
  name = "prometheus_data"
}

resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = docker_image.prometheus.image_id

  restart = "unless-stopped"

  ports {
    internal = 9090
    external = 9090
  }

  volumes {
    volume_name    = docker_volume.prometheus_data.name
    container_path = "/prometheus"
  }

  upload {
    content = file("${path.module}/configs/prometheus/prometheus.yaml")
    file    = "/etc/prometheus/prometheus.yml"
  }

  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus",
    "--storage.tsdb.retention.time=${var.prometheus_retention_period}",
    "--web.enable-lifecycle",
    "--web.enable-remote-write-receiver",
  ]

  memory = var.prometheus_memory_limit

  networks_advanced {
    name = docker_network.monitoring.id
  }
}

# -----------------------------------------------------------------------------
# Alloy
# -----------------------------------------------------------------------------
resource "docker_image" "alloy" {
  name         = "grafana/alloy:v${var.alloy_version}"
  keep_locally = true
}

resource "docker_container" "alloy" {
  name    = "alloy"
  image   = docker_image.alloy.image_id
  restart = "unless-stopped"

  command = [
    "run",
    "--server.http.listen-addr=0.0.0.0:12345",
    "/etc/alloy/config.alloy",
  ]

  ports {
    internal = 12345
    external = 12345
  }

  # OTLP gRPC receiver
  ports {
    internal = 4317
    external = 4317
  }

  # OTLP HTTP receiver
  ports {
    internal = 4318
    external = 4318
  }

  upload {
    content = file("${path.module}/configs/alloy/config.alloy")
    file    = "/etc/alloy/config.alloy"
  }

  # Mount Docker socket so Alloy can discover containers
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = true
  }

  memory = var.alloy_memory_limit

  networks_advanced {
    name = docker_network.monitoring.id
  }

  depends_on = [
    docker_container.loki,
    docker_container.prometheus,
  ]
}
