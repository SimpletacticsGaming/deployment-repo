#terraform {
#  required_version = ">= 1.0"
#
#  backend "pg" {
#    # conn_str is provided via the PG_CONN_STR environment variable
#    # or via: terraform init -backend-config="conn_str=postgres://terraform:PASSWORD@VPS_IP/terraform_state"
#    schema_name = "dev"
#  }
#
#  required_providers {
#    docker = {
#      source  = "kreuzwerker/docker"
#      version = "~> 3.0"
#    }
#  }
#}
#
#provider "docker" {
#  host = var.docker_host
#}
#
## -----------------------------------------------------------------------------
## Variables
## -----------------------------------------------------------------------------
#
#variable "docker_host" {
#  description = "Docker host URI (SSH to VPS)"
#  type        = string
#}
#
#variable "nexus_stack_name" {
#  description = "Docker stack name for the Nexus deployment"
#  type        = string
#  default     = "nexus-dev"
#}
#
#variable "nexus_port" {
#  description = "Host port to expose the Nexus web UI on"
#  type        = number
#  default     = 8081
#}
#
#variable "grafana_admin_password" {
#  description = "Grafana admin password"
#  type        = string
#  sensitive   = true
#  default     = "admin"
#}
#
## -----------------------------------------------------------------------------
## Modules
## -----------------------------------------------------------------------------
#
#module "nexus" {
#  source = "../../modules/nexus"
#
#  stack_name = var.nexus_stack_name
#  nexus_port = var.nexus_port
#}
#
#module "monitoring" {
#  source = "../../modules/monitoring"
#
#  grafana_admin_password = var.grafana_admin_password
#}
#
## -----------------------------------------------------------------------------
## Outputs
## -----------------------------------------------------------------------------
#
#output "nexus_url" {
#  description = "URL to access Nexus"
#  value       = module.nexus.nexus_url
#}
#
#output "grafana_url" {
#  description = "URL to access Grafana"
#  value       = module.monitoring.grafana_url
#}
#
## -----------------------------------------------------------------------------
## Add future modules here, e.g.:
## module "aoc" {
##   source     = "../../../aoc/terraform"
##   stack_name = "aoc-dev"
## }
## -----------------------------------------------------------------------------
#
