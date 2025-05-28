variable "resource_group_name" {
  description = "Base name of the resource group (will be suffixed with environment)"
  type        = string
  default     = "kraislauf"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "germanywestcentral"
}

variable "project_name" {
  description = "Name of the project used in resource naming"
  type        = string
  default     = "kraislauf"
}

variable "environment" {
  description = "Environment (dev, prd)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prd"], var.environment)
    error_message = "Environment must be either 'dev' or 'prd'."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "kraislauf"
    Environment = var.environment == "dev" ? "Development" : "Production"
    ManagedBy   = "OpenTofu"
  }
}
