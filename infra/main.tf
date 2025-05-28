terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"

  # Backend configuration will be provided via -backend-config flag during initialization
  # Always use the remote state backend to ensure consistent state management
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

# Local variables for environment-specific configurations
locals {
  environment_config = {
    dev = {
      sku_tier     = "Standard"
      sku_size     = "Standard"
      acr_sku      = "Basic"
      min_replicas = 1
      max_replicas = 3
    }
    prd = {
      sku_tier     = "Standard"
      sku_size     = "Standard"
      acr_sku      = "Standard"
      min_replicas = 2
      max_replicas = 5
    }
  }

  # Use the current environment configuration
  config = local.environment_config[var.environment]

  # Set common name prefix with environment
  name_prefix = "${var.project_name}-${var.environment}"

  # Update tags with current environment
  tags = merge(var.tags, {
    Environment = var.environment == "dev" ? "Development" : "Production"
  })
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.tags
}

# Static Web App for frontend
resource "azurerm_static_site" "frontend" {
  name                = "${local.name_prefix}-web"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku_tier            = local.config.sku_tier
  sku_size            = local.config.sku_size
  tags                = local.tags
}

# Container Registry for backend Docker images
resource "azurerm_container_registry" "acr" {
  name                = replace("${var.project_name}${var.environment}acr", "-", "")
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = local.config.acr_sku
  admin_enabled       = true
  tags                = local.tags
}

# Log Analytics workspace for Container App
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "${local.name_prefix}-logs"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# Container App Environment
resource "azurerm_container_app_environment" "env" {
  name                       = "${local.name_prefix}-env"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = var.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  tags                       = local.tags
}

# Container App for backend
resource "azurerm_container_app" "backend" {
  name                         = "${local.name_prefix}-api"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  tags                         = local.tags

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
        value = var.environment == "dev" ? "debug" : "info"
      }
    }

    min_replicas = local.config.min_replicas
    max_replicas = local.config.max_replicas
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
