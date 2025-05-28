# Infrastructure as Code (IaC) with OpenTofu

This project uses OpenTofu (an open-source Terraform alternative) to provision and manage Azure infrastructure.

## GitHub Actions Workflow

The project includes a GitHub Actions workflow that automatically plans and applies infrastructure changes:

- On pull requests: validates configuration and generates a plan
- On merges to main: applies the changes to the dev environment
- On releases: applies the changes to the production environment
- Manual trigger: allows deploying to either dev or prd environment (useful for testing changes in feature branches)

## Setup Instructions

### 1. Create Azure Service Principal

To allow GitHub Actions to authenticate with Azure, create a service principal:

```bash
az login
az ad sp create-for-rbac --name "kraislauf-github-actions" --role contributor \
                          --scopes /subscriptions/{subscription-id} \
                          --sdk-auth
```

This command will output a JSON object containing credentials.

### 2. Configure GitHub Secrets

Add the following secret to your GitHub repository:

- `AZURE_CREDENTIALS`: The entire JSON output from the service principal creation

### 3. Configure Backend Storage (Optional)

For production use, it's recommended to configure a remote backend for state storage:

1. Create an Azure Storage Account:

```bash
az storage account create --name kraislauftofu --resource-group kraislauf-rg \
                          --sku Standard_LRS --encryption-services blob
```

2. Create a container for the state file:

```bash
az storage container create --name tfstate --account-name kraislauftofu
```

3. Update the `main.tf` file to use the Azure backend:

```terraform
terraform {
  backend "azurerm" {
    resource_group_name  = "kraislauf-rg"
    storage_account_name = "kraislauftofu"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
  # ... existing provider configuration
}
```

## Workflow Details

The GitHub Actions workflow consists of four main jobs:

1. **Validate**: Checks that the OpenTofu configuration is correctly formatted and syntactically valid.
2. **Plan**: Creates an execution plan and posts a summary as a comment on pull requests.
3. **Apply to Dev**: Applies the changes to the dev environment when:
   - Code is merged to the main branch
   - The workflow is manually triggered with "dev" environment selected
4. **Apply to Production**: Applies the changes to the production environment when:
   - A new release is published
   - The workflow is manually triggered with "prd" environment selected

This separation of environments allows for a proper development and testing workflow before deploying to production.

## Local Development

For local development, install OpenTofu:

```bash
# Install OpenTofu
brew install opentofu/tap/opentofu

# Initialize (in the infra directory)
cd infra
tofu init

# Plan changes
tofu plan

# Apply changes
tofu apply
```

## Branching Strategy and Deployment Flow

This project follows a structured branching and deployment strategy:

1. **Feature Branches**: Developers create feature branches from `main` for infrastructure changes.
   - Can run validation and plan through PR process
   - Can manually trigger deployments to `dev` for testing purposes

2. **Main Branch**: Represents the latest development state.
   - All merged PRs automatically deploy to the `dev` environment
   - Used for integration testing and verification

3. **Releases**: Used for production deployments.
   - Create a GitHub release to deploy to the `prd` environment
   - Provides a clear history of production deployments

### Environment Variables

The deployment process automatically sets the environment variable based on the target:

- For dev: `TF_VAR_environment="dev"`
- For production: `TF_VAR_environment="prd"`

This ensures that environment-specific configurations are properly applied.
