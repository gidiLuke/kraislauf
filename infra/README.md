# kraislauf Infrastructure

This folder contains the Infrastructure as Code (IaC) configuration for the kraislauf application using OpenTofu (a Terraform alternative).

## Azure Resources

The infrastructure defines the following Azure resources:

- Resource Group
- Static Web App (for the frontend)
- Container Registry (for Docker images)
- Container App (for the backend API)
- Log Analytics Workspace (for monitoring)

## Getting Started

### Prerequisites

- Azure CLI installed and authenticated
- OpenTofu or Terraform installed

### Deployment

1. Initialize OpenTofu:

```bash
tofu init
```

2. Create a plan:

```bash
tofu plan -out=plan.out
```

3. Apply the changes:

```bash
tofu apply plan.out
```

### Configuration

The infrastructure is configured through variables defined in `variables.tf`. You can override them by creating a `terraform.tfvars` file:

```hcl
resource_group_name = "kraislauf-prod-rg"
location            = "westus2"
environment         = "production"
```

## Environments

The infrastructure supports multiple environments (dev, test, prod) through variable configurations.

## Outputs

After deployment, important information like endpoints and credentials are provided as outputs. View them with:

```bash
tofu output
```
