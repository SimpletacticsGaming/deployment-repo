variable "stack_name" {
  description = "Name of the Docker stack for the Nexus deployment"
  type        = string
}

variable "nexus_version" {
  description = "Sonatype Nexus Repository Docker image tag"
  type        = string
  default     = "3.78.1"
}

variable "nexus_port" {
  description = "Host port to expose the Nexus web UI on"
  type        = number
  default     = 8081
}

variable "nexus_replicas" {
  description = "Number of Nexus service replicas"
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# Memory & JVM
# -----------------------------------------------------------------------------

variable "nexus_memory_limit" {
  description = "Memory limit for the Nexus container in MB"
  type        = number
  default     = 2048
}

variable "nexus_memory_reservation" {
  description = "Memory reservation for the Nexus container in MB"
  type        = number
  default     = 1024
}

variable "nexus_jvm_heap_size" {
  description = "JVM -Xms and -Xmx heap size (e.g. 1200m, 2g)"
  type        = string
  default     = "1200m"
}

variable "nexus_jvm_max_direct_memory" {
  description = "JVM MaxDirectMemorySize (e.g. 2g)"
  type        = string
  default     = "2g"
}
