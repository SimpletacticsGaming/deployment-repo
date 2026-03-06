variable "grafana_version" {
  description = "Grafana Docker image tag"
  type        = string
  default     = "11.4.0"
}

variable "alloy_version" {
  description = "Grafana Alloy Docker image tag"
  type        = string
  default     = "1.5.1"
}

variable "loki_version" {
  description = "Grafana Loki Docker image tag"
  type        = string
  default     = "3.3.2"
}

variable "prometheus_version" {
  description = "Prometheus Docker image tag"
  type        = string
  default     = "2.55.1"
}

variable "grafana_port" {
  description = "Host port to expose Grafana on"
  type        = number
  default     = 3000
}

variable "grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "monitoring_network_name" {
  description = "Name of the Docker network for the monitoring stack"
  type        = string
  default     = "monitoring"
}

# -----------------------------------------------------------------------------
# Memory Limits (MB)
# -----------------------------------------------------------------------------

variable "grafana_memory_limit" {
  description = "Memory limit for the Grafana container in MB"
  type        = number
  default     = 512
}

variable "alloy_memory_limit" {
  description = "Memory limit for the Alloy container in MB"
  type        = number
  default     = 256
}

variable "loki_memory_limit" {
  description = "Memory limit for the Loki container in MB"
  type        = number
  default     = 512
}

variable "prometheus_memory_limit" {
  description = "Memory limit for the Prometheus container in MB"
  type        = number
  default     = 512
}

# -----------------------------------------------------------------------------
# Retention
# -----------------------------------------------------------------------------

variable "loki_retention_period" {
  description = "Loki log retention period"
  type        = string
  default     = "168h"
}

variable "prometheus_retention_period" {
  description = "Prometheus metrics retention period"
  type        = string
  default     = "15d"
}
