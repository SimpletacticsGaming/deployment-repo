terraform {
  required_version = ">= 1.0"

  # Bootstrap uses LOCAL state — this is the only exception.
  # Keep terraform.tfstate safe — losing it means losing track
  # of the state-backend container itself.

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = var.docker_host
}

# -----------------------------------------------------------------------------
# PostgreSQL — Terraform State Backend
# -----------------------------------------------------------------------------

resource "docker_image" "postgres" {
  name         = "postgres:${var.postgres_version}"
  keep_locally = true
}

resource "docker_volume" "pg_data" {
  name = "terraform-state-pg-data"
}

resource "docker_container" "postgres" {
  name  = "terraform-state-db"
  image = docker_image.postgres.image_id

  restart = "unless-stopped"

  env = [
    "POSTGRES_USER=terraform",
    "POSTGRES_PASSWORD=${var.postgres_password}",
    "POSTGRES_DB=terraform_state",
  ]

  ports {
    internal = 5432
    external = var.postgres_port
  }

  volumes {
    volume_name    = docker_volume.pg_data.name
    container_path = "/var/lib/postgresql/data"
  }
}
