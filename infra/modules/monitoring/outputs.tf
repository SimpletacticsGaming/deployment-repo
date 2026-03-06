output "grafana_url" {
  description = "URL to access Grafana"
  value       = "http://localhost:${var.grafana_port}"
}

output "grafana_container_name" {
  description = "Name of the Grafana container"
  value       = docker_container.grafana.name
}

output "alloy_container_name" {
  description = "Name of the Alloy container"
  value       = docker_container.alloy.name
}

output "loki_url" {
  description = "Internal Loki URL for sending logs"
  value       = "http://${docker_container.loki.name}:3100"
}

output "prometheus_url" {
  description = "Internal Prometheus URL for metrics"
  value       = "http://${docker_container.prometheus.name}:9090"
}

output "monitoring_network_name" {
  description = "Name of the Docker monitoring network"
  value       = docker_network.monitoring.name
}
