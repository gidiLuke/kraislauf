#!/bin/bash
# setup-github-oidc.sh - Configure GitHub OIDC authentication for Azure
# Usage: ./setup-github-oidc.sh [environment]

set -e

# Ensure environment parameter is provided
ENVIRONMENT=${1:-}
if [ -z "$ENVIRONMENT" ]; then
    echo "Error: Environment parameter is required."
    echo "Usage: ./setup-github-oidc.sh [dev|prd]"
    exit 1
fi

# Validate environment parameter
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prd" ]]; then
    echo "Invalid environment: $ENVIRONMENT. Must be either 'dev' or 'prd'."
    exit 1
fi

RESOURCE_GROUP_NAME="rg-kraislauf-infra"
LOCATION="germanywestcentral"

# Detect GitHub repository info from git remote
GITHUB_REPO_OWNER="$(git config --get remote.origin.url | sed -n 's/.*github.com[:/]\([^/]*\).*/\1/p')"
GITHUB_REPO_NAME="$(git config --get remote.origin.url | sed -n 's/.*\/\([^/]*\)\.git$/\1/p')"

if [[ -z "$GITHUB_REPO_OWNER" || -z "$GITHUB_REPO_NAME" ]]; then
    echo "Could not automatically detect GitHub repository info."
    read -p "Enter GitHub repository owner (organization or username): " GITHUB_REPO_OWNER
    read -p "Enter GitHub repository name: " GITHUB_REPO_NAME
fi

echo "Setting up OIDC authentication for GitHub repository: $GITHUB_REPO_OWNER/$GITHUB_REPO_NAME"

# Create a user-assigned managed identity for GitHub Actions
IDENTITY_NAME="id-kraislauf-github"

# Check if the identity already exists
IDENTITY_EXISTS=$(az identity show --name "$IDENTITY_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "name" --output tsv 2>/dev/null || echo "false")

if [[ "$IDENTITY_EXISTS" == "false" ]]; then
    echo "Creating managed identity for GitHub Actions..."
    az identity create --name "$IDENTITY_NAME" --resource-group "$RESOURCE_GROUP_NAME" --location "$LOCATION"
fi

# Get identity client ID and principal ID
IDENTITY_CLIENT_ID=$(az identity show --name "$IDENTITY_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "clientId" --output tsv)
IDENTITY_PRINCIPAL_ID=$(az identity show --name "$IDENTITY_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "principalId" --output tsv)

# Source the environment file to get the storage account name
if [ -f .env.infra.${ENVIRONMENT} ]; then
    source .env.infra.${ENVIRONMENT}
else
    echo "Error: .env.infra.${ENVIRONMENT} file not found. Run ./backend-config.sh ${ENVIRONMENT} first."
    exit 1
fi

# Assign Storage Blob Data Contributor role to the managed identity
echo "Assigning Storage Blob Data Contributor role to managed identity..."
STORAGE_ID=$(az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "id" --output tsv)

# Check if role assignment already exists to avoid errors
ROLE_EXISTS=$(az role assignment list --assignee "$IDENTITY_PRINCIPAL_ID" --scope "$STORAGE_ID" --role "Storage Blob Data Contributor" --query "[].id" --output tsv)

if [[ -z "$ROLE_EXISTS" ]]; then
    az role assignment create \
        --assignee-object-id "$IDENTITY_PRINCIPAL_ID" \
        --assignee-principal-type "ServicePrincipal" \
        --role "Storage Blob Data Contributor" \
        --scope "$STORAGE_ID"
fi

# Also assign Contributor role for broader permissions if needed
CONTRIBUTOR_EXISTS=$(az role assignment list --assignee "$IDENTITY_PRINCIPAL_ID" --scope "$STORAGE_ID" --role "Contributor" --query "[].id" --output tsv)

if [[ -z "$CONTRIBUTOR_EXISTS" ]]; then
    az role assignment create \
        --assignee-object-id "$IDENTITY_PRINCIPAL_ID" \
        --assignee-principal-type "ServicePrincipal" \
        --role "Contributor" \
        --scope "$STORAGE_ID"
fi

# Set up federated identity credential for GitHub Actions
echo "Setting up federated identity credentials for GitHub Actions..."

# Setup for environments
for ENV in "dev" "prd"; do
    CREDENTIAL_NAME="fc-github-$ENV"
    CREDENTIAL_EXISTS=$(az identity federated-credential list --identity-name "$IDENTITY_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "[?name=='$CREDENTIAL_NAME'].name" --output tsv 2>/dev/null || echo "")

    if [[ -z "$CREDENTIAL_EXISTS" ]]; then
        echo "Creating federated credential for $ENV environment..."
        az identity federated-credential create \
            --name "$CREDENTIAL_NAME" \
            --identity-name "$IDENTITY_NAME" \
            --resource-group "$RESOURCE_GROUP_NAME" \
            --issuer "https://token.actions.githubusercontent.com" \
            --subject "repo:${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}:environment:$ENV" \
            --audiences "api://AzureADTokenExchange"
    else
        echo "Federated credential for $ENV environment already exists."
    fi
done

# Output the values needed for GitHub Actions
echo ""
echo "===== VALUES FOR GITHUB REPOSITORY SECRETS ====="
echo "Add these secrets to your GitHub repository:"
echo ""
echo "AZURE_CLIENT_ID: $IDENTITY_CLIENT_ID"
echo "AZURE_TENANT_ID: $(az account show --query tenantId -o tsv)"
echo "AZURE_SUBSCRIPTION_ID: $(az account show --query id -o tsv)"
echo ""
echo "================================================"
echo ""
echo "Also ensure you have created the 'dev' and 'prd' environments in your GitHub repository settings."
