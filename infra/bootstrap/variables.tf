variable "docker_host" {
  description = "Docker host URI (SSH to VPS)"
  type        = string
}

variable "postgres_password" {
  description = "Password for the terraform PostgreSQL user"
  type        = string
  sensitive   = true
}

variable "postgres_port" {
  description = "Host port to expose PostgreSQL on"
  type        = number
  default     = 5432
  sensitive   = true
}

variable "postgres_version" {
  description = "PostgreSQL Docker image tag"
  type        = string
  default     = "16-alpine"
}
