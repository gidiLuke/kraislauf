terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Static Web App for frontend
resource "azurerm_static_site" "frontend" {
  name                = "${var.project_name}-web"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku_tier            = "Standard"
  sku_size            = "Standard"
  tags                = var.tags
}

# Container Registry for backend Docker images
resource "azurerm_container_registry" "acr" {
  name                = replace("${var.project_name}acr", "-", "")
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
  tags                = var.tags
}

# Log Analytics workspace for Container App
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "${var.project_name}-logs"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Container App Environment
resource "azurerm_container_app_environment" "env" {
  name                       = "${var.project_name}-env"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = var.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  tags                       = var.tags
}

# Container App for backend
resource "azurerm_container_app" "backend" {
  name                         = "${var.project_name}-api"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  tags                         = var.tags

  template {
    container {
      name   = "backend"
      image  = "${azurerm_container_registry.acr.login_server}/${var.project_name}-backend:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      env {
        name  = "LOG_LEVEL"
        value = "info"
      }
    }

    min_replicas = 1
    max_replicas = 5
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    transport        = "http"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
