output "nexus_url" {
  description = "URL to access Nexus Repository"
  value       = "http://localhost:${var.nexus_port}"
}

output "service_name" {
  description = "Name of the Nexus Docker Swarm service"
  value       = docker_service.nexus.name
}

output "network_name" {
  description = "Name of the Docker network used by the Nexus stack"
  value       = docker_network.nexus.name
}

output "volume_name" {
  description = "Name of the Docker volume for Nexus data persistence"
  value       = docker_volume.nexus_data.name
}
