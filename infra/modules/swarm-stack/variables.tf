variable "stack_name" {
  description = "Name of the Docker stack (used as prefix for service names)"
  type        = string
}

variable "services" {
  description = "Map of services from merged service.yaml configuration"
  type = map(object({
    image = object({
      repository = string
      tag        = string
    })
    replicas = optional(number, 1)
    resources = optional(object({
      limits = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
      reservations = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
    }))
    update = optional(object({
      parallelism = optional(number, 1)
      order       = optional(string, "stop-first")
      delay       = optional(string, "10s")
    }))
    restart = optional(object({
      condition = optional(string, "on-failure")
      delay     = optional(string, "5s")
    }))
    environment = optional(list(object({
      name  = string
      value = string
    })), [])
    secrets = optional(list(object({
      name   = optional(string)
      source = optional(string)
      target = optional(string)
      mode   = optional(string, "0444")
    })), [])
    networks = optional(list(string), [])
    healthcheck = optional(object({
      test     = list(string)
      interval = optional(string, "30s")
      timeout  = optional(string, "10s")
      retries  = optional(number, 3)
    }))
  }))
}

variable "networks" {
  description = "Map of networks from service.yaml configuration"
  type = map(object({
    external = optional(bool, false)
    driver   = optional(string, "overlay")
  }))
  default = {}
}

variable "volumes" {
  description = "Map of volumes to create for the stack"
  type = map(object({
    driver = optional(string, "local")
  }))
  default = {}
}

variable "secret_ids" {
  description = "Map of secret names to their Docker secret IDs (looked up externally)"
  type        = map(string)
  default     = {}
}
