# kraislauf Infrastructure

This folder contains the Infrastructure as Code (IaC) configuration for the kraislauf application using OpenTofu (a Terraform alternative).

## Azure Resources

The infrastructure defines the following Azure resources:

- Resource Group
- Static Web App (for the frontend)
- Container Registry (for Docker images)
- Container App (for the backend API)
- Log Analytics Workspace (for monitoring)

### Azure Naming Conventions

All Azure resources follow Microsoft's recommended naming conventions:

| Resource Type | Pattern | Example |
|---------------|---------|---------|
| Resource Group | rg-{workload}-{purpose} | rg-kraislauf-infra |
| Storage Account | st{workload}{random} | stkraislauf1a2b |
| Managed Identity | id-{workload}-{purpose} | id-kraislauf-github |
| Federated Credential | fc-{purpose}-{env} | fc-github-dev |
| Container Registry | cr{workload}{env} | crkraislaufdev |
| Container App | ca-{workload}-{purpose}-{env} | ca-kraislauf-api-dev |
| Log Analytics | log-{workload}-{env} | log-kraislauf-dev |

These naming conventions ensure consistency and make resources easier to identify and manage.

## Environment-Based Deployment

The infrastructure supports two environments:

- **dev**: Development environment for testing
- **prd**: Production environment for live usage

Environment-specific configurations are defined in `locals` block in `main.tf` and include:

- Different replica counts
- Different registry SKUs
- Environment-specific naming
- Different logging levels

## State Management

State is managed using Azure Storage as a remote backend. This ensures consistent state management across all environments and team members. **All operations, including local development, use this remote state** to avoid state conflicts and ensure everyone is working with the same infrastructure state.

The `backend-config.sh` script helps set up the necessary storage resources and configure the backend based on the target environment.

### Storage Account Security

The Terraform/OpenTofu state backend storage account is secured with the following features:

- **Azure-compliant naming**: The storage account follows Azure naming conventions (`st<name><random>`)
- **Randomized name**: The storage account name includes a random 4-letter suffix for global uniqueness
- **Network restrictions**: Access is denied by default, with explicit IP whitelisting required
- **OIDC authentication**: GitHub Actions uses OIDC (OpenID Connect) for keyless authentication
- **Azure AD authentication**: No storage account keys are used in regular operations
- **Enhanced security settings**:
  - TLS 1.2 enforcement
  - Versioning enabled for state files
  - Soft delete enabled (7-day retention)
  - Public access to blobs blocked
  - HTTPS-only access

## Local Development Guide

This section provides step-by-step instructions for setting up and managing the infrastructure locally.

### Prerequisites

1. **Install the Azure CLI**:

   ```bash
   # On macOS:
   brew update && brew install azure-cli
   ```

2. **Install OpenTofu**:

   ```bash
   # On macOS:
   brew install opentofu/tap/opentofu
   ```

3. **Login to Azure**:

   ```bash
   az login
   ```

4. **Select the correct subscription** (if you have multiple):

   ```bash
   # List subscriptions
   az account list --output table
   
   # Select a subscription
   az account set --subscription "Your-Subscription-ID"
   ```

### Setting Up the Backend

The infrastructure uses an Azure Storage Account as a remote backend to store the Terraform/OpenTofu state. This ensures consistent state management across team members and CI/CD environments.

```bash
# Setup the backend for development environment
chmod +x backend-config.sh
./backend-config.sh dev
```

This script will:

- Create a resource group for the state storage (if it doesn't exist)
- Create an Azure Storage Account with a random suffix for uniqueness (if it doesn't exist)
- Configure network security (deny public access by default)
- Add your current IP address to the allowed list
- Set up OIDC authentication for GitHub Actions
- Create a blob container for the state files (if it doesn't exist)
- Create an environment-specific storage account configuration file (`.env.infra.dev` or `.env.infra.prd`)
- Generate a backend configuration file (`backend-dev.tfvars` or `backend-prd.tfvars`)

> **Important**: Always use the remote backend, even for local development. This prevents state conflicts and ensures everyone is working with the same infrastructure state.

### Managing IP Whitelisting for Local Development

Since the storage account has network restrictions enabled, you need to ensure your IP is whitelisted whenever your IP changes or when working from a new location.

Use the provided `manage-ip-whitelist.sh` script to easily manage IP whitelisting:

```bash
# Add your current IP to the allowed list for dev environment
./manage-ip-whitelist.sh add dev

# List all currently allowed IPs for dev environment
./manage-ip-whitelist.sh list dev

# Show your current public IP (environment parameter still required)
./manage-ip-whitelist.sh show-current dev

# Remove your current IP from the allowed list for production environment
./manage-ip-whitelist.sh remove prd

# Remove a specific IP from the allowed list for dev environment
./manage-ip-whitelist.sh remove dev 123.123.123.123
```

This script uses the environment-specific `.env.infra.{env}` file created by the `backend-config.sh` script to determine the storage account name.

### Quick Start

For local development with direct commands and remote state:

```bash
# 1. Setup remote backend storage and configuration
chmod +x backend-config.sh
./backend-config.sh dev

# 2. Initialize OpenTofu with remote backend
tofu init -backend-config=backend-dev.tfvars

# 3. Set environment variable
export TF_VAR_environment=dev

# 4. Plan changes
tofu plan -out=dev-plan.out

# 5. Apply changes
tofu apply dev-plan.out
```

### Working with Infrastructure

Follow these steps for managing infrastructure:

#### Development Environment

```bash
# Setup backend and initialize
./backend-config.sh dev
tofu init -backend-config=backend-dev.tfvars

# Set environment variable
export TF_VAR_environment=dev

# Plan and review changes
tofu plan -out=dev-plan.out

# Apply changes
tofu apply dev-plan.out

# View outputs after deployment
tofu output

# If needed, destroy resources
tofu destroy
```

### Working with Multiple Environments

When switching between environments:

1. **Production Environment**:

   ```bash
   # Setup production backend
   ./backend-config.sh prd
   
   # Initialize with production backend config
   tofu init -reconfigure -backend-config=backend-prd.tfvars
   
   # Set environment variable
   export TF_VAR_environment=prd
   
   # Plan and apply changes
   tofu plan -out=prd-plan.out
   tofu apply prd-plan.out
   ```

2. **Switching Back to Development**:

   ```bash
   # Switch back to dev backend
   ./backend-config.sh dev
   tofu init -reconfigure -backend-config=backend-dev.tfvars
   export TF_VAR_environment=dev
   ```

This ensures you're working with the correct state file for each environment.

### Configuration

The infrastructure is configured through variables defined in `variables.tf`. You can override them by creating a `terraform.tfvars` file:

```hcl
location            = "germanywestcentral"
project_name        = "kraislauf"
environment         = "dev"
```

### Checking Resource Status

To check the status of deployed resources:

```bash
# List resource groups
az group list --query "[].name" -o tsv

# List resources in a specific group
az resource list --resource-group kraislauf-dev-rg -o table
```

### Troubleshooting

#### Backend Configuration Issues

If you encounter issues with the backend configuration:

1. Verify Azure authentication:

   ```bash
   az account show
   ```

2. Check if the storage account exists:

   ```bash
   source .env.infra
   az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group rg-kraislauf-infra
   ```

3. Check if your IP is whitelisted:

   ```bash
   ./manage-ip-whitelist.sh show-current
   ./manage-ip-whitelist.sh list
   ```

4. If your IP is not whitelisted, add it:

   ```bash
   ./manage-ip-whitelist.sh add
   ```

#### Network Restriction Issues

If you encounter "AuthorizationPermissionMismatch" or "NetworkAuthorizationMismatch" errors:

1. Your IP may have changed. Check your current IP and the allowed IPs:

   ```bash
   ./manage-ip-whitelist.sh show-current
   ./manage-ip-whitelist.sh list
   ```

2. Add your current IP to the allowed list:

   ```bash
   ./manage-ip-whitelist.sh add
   ```

3. If working from multiple locations, remember to whitelist each location's IP address.

#### State Lock Issues

If the state is locked (usually due to interrupted operations):

1. List blobs in the container to find the lease:

   ```bash
   az storage blob list --container-name tfstate --account-name kraislauftofu
   ```

2. Break the lease on the state file:

   ```bash
   az storage blob lease break --container-name tfstate --blob-name terraform.dev.tfstate --account-name kraislauftofu
   ```

## GitHub Actions Integration

This project uses GitHub Actions for automated infrastructure provisioning:

- **Pull Requests**: Validates configuration and generates a plan
- **Merges to main**: Automatically deploys to the dev environment
- **Releases**: Deploys to the production environment
- **Manual triggers**: Allows deploying to either environment

### OIDC Authentication with Azure

The workflow uses OIDC (OpenID Connect) for secure, keyless authentication with Azure:

1. When running the `backend-config.sh` script, a managed identity and federated credentials are created in Azure
2. GitHub Actions uses workload identity federation to authenticate without storing sensitive credentials

To set up this integration:

1. Run the `setup-github-oidc.sh` script to configure the Azure resources required for OIDC:

```bash
# Set up OIDC authentication for GitHub Actions for the dev environment
chmod +x setup-github-oidc.sh
./setup-github-oidc.sh dev

# For the production environment
./setup-github-oidc.sh prd
```

2. Add the following secrets to your GitHub repository (the script will provide these values):
   - `AZURE_CLIENT_ID`: The Client ID of the managed identity
   - `AZURE_TENANT_ID`: Your Azure tenant ID
   - `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID

3. Ensure the GitHub environments (`dev` and `prd`) are properly configured in your repository settings

See the `.github/workflows/README.md` for more details on CI/CD setup.

## Outputs

After deployment, important information like endpoints and credentials are provided as outputs. View them with:

```bash
tofu output
```

### Example: Complete Workflow

Here's an example of a complete workflow to update infrastructure in both environments:

```bash
# Setup for dev environment
./backend-config.sh dev
tofu init -backend-config=backend-dev.tfvars
export TF_VAR_environment=dev

# Make changes to infrastructure files (e.g., main.tf, variables.tf)

# Plan and review changes for dev
tofu plan -out=dev-plan.out
# Review the plan output carefully

# Apply changes to dev
tofu apply dev-plan.out

# Test the changes in the dev environment

# When ready for production:
./backend-config.sh prd
tofu init -reconfigure -backend-config=backend-prd.tfvars
export TF_VAR_environment=prd

# Plan and review changes for production
tofu plan -out=prd-plan.out
# Review the plan output carefully

# Apply changes to production
tofu apply prd-plan.out
```

This workflow ensures changes are tested in dev before being applied to production, while maintaining separate state files for each environment.
