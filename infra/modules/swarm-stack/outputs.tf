output "service_ids" {
  description = "Map of service names to their Docker service IDs"
  value = {
    for name, svc in docker_service.service : name => svc.id
  }
}

output "service_names" {
  description = "Map of service names to their full Docker service names (stack_name prefix)"
  value = {
    for name, svc in docker_service.service : name => svc.name
  }
}

output "stack_name" {
  description = "The stack name used for all resources"
  value       = var.stack_name
}
