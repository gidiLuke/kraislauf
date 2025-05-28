output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "static_web_app_url" {
  description = "The URL of the deployed Static Web App"
  value       = azurerm_static_site.frontend.default_host_name
}

output "container_app_url" {
  description = "The URL of the deployed Container App"
  value       = azurerm_container_app.backend.ingress[0].fqdn
}

output "container_registry_url" {
  description = "The URL of the container registry"
  value       = azurerm_container_registry.acr.login_server
}

output "container_registry_admin_username" {
  description = "The admin username for the container registry"
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "container_registry_admin_password" {
  description = "The admin password for the container registry"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}
