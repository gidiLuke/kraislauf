variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "kraislauf-rg"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "Name of the project used in resource naming"
  type        = string
  default     = "kraislauf"
}

variable "environment" {
  description = "Environment (dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "kraislauf"
    Environment = "Development"
    ManagedBy   = "OpenTofu"
  }
}
