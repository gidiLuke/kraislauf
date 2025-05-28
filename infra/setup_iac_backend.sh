#!/bin/bash -x
# setup_iac_backend.sh - Configures the Terraform/OpenTofu backend for different environments
# Usage: ./setup_iac_backend.sh [dev|prd]

# Treat unset variables as errors and catch failures in piped commands
set -euo pipefail
IFS=$'\n\t'

# Global configuration variables
PROJECT_NAME="kraislauf"
LOCATION="germanywestcentral"
STORAGE_SKU="Standard_LRS"

# Get Azure tenant and subscription information once
AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)
AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Ensure environment parameter is provided
if [ -z "$1" ]; then
    echo "Error: Environment parameter is required."
    exit 1
fi

ENVIRONMENT=$1

# Validate environment parameter
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prd" ]]; then
    echo "Invalid environment: $ENVIRONMENT. Must be either 'dev' or 'prd'."
    exit 1
fi

echo "Configuring backend for $ENVIRONMENT environment..."
if [ -f ".env.infra.${ENVIRONMENT}" ]; then
    # shellcheck disable=SC1090
    source ".env.infra.${ENVIRONMENT}"
else
    RANDOM_SUFFIX=$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | fold -w 4 | head -n1)
    STORAGE_ACCOUNT_NAME="st${PROJECT_NAME}${RANDOM_SUFFIX}"
    echo "STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME}" >".env.infra.${ENVIRONMENT}"
fi
RESOURCE_GROUP_NAME="rg-${PROJECT_NAME}-infra"
CONTAINER_NAME="tfstate"

# Save the generated storage account name to a local file for reference with environment postfix
echo "STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME}" >".env.infra.${ENVIRONMENT}"

# Check if resource group exists
RG_EXISTS=$(az group exists --name "${RESOURCE_GROUP_NAME}" --output tsv)

if [[ "${RG_EXISTS}" == "false" ]]; then
    echo "Creating resource group: ${RESOURCE_GROUP_NAME}"
    az group create --name "${RESOURCE_GROUP_NAME}" --location "${LOCATION}" --tags "Purpose=Terraform State" "Environment=All"
fi

# Check if storage account exists
STORAGE_EXISTS=$(az storage account check-name --name "${STORAGE_ACCOUNT_NAME}" --query "nameAvailable" --output tsv)

if [[ "${STORAGE_EXISTS}" == "true" ]]; then
    echo "Creating storage account: ${STORAGE_ACCOUNT_NAME}"
    # Create storage account with enhanced security settings but without network restrictions initially
    az storage account create \
        --name "${STORAGE_ACCOUNT_NAME}" \
        --resource-group "${RESOURCE_GROUP_NAME}" \
        --location "${LOCATION}" \
        --sku "${STORAGE_SKU}" \
        --encryption-services blob \
        --enable-infrastructure-encryption \
        --min-tls-version "TLS1_2" \
        --allow-blob-public-access false \
        --auth-mode login \
        --default-action-for-keys deny \
        --https-only true \
        --tags "Purpose=Terraform State" "Environment=All"

    # Enable versioning and soft delete for data protection
    az storage account blob-service-properties update \
        --account-name "${STORAGE_ACCOUNT_NAME}" \
        --resource-group "${RESOURCE_GROUP_NAME}" \
        --enable-versioning true \
        --enable-delete-retention true \
        --delete-retention-days 7
fi

# Configure RBAC for GitHub OIDC
echo "Configuring RBAC for GitHub OIDC integration..."
GITHUB_REPO_OWNER="$(git config --get remote.origin.url | sed -n 's/.*github.com[:/]\([^/]*\).*/\1/p')"
GITHUB_REPO_NAME="$(git config --get remote.origin.url | sed -n 's/.*\/\([^/]*\)\.git$/\1/p')"

# Create an Entra ID group for infrastructure administrators
INFRA_ADMIN_GROUP_NAME="${PROJECT_NAME}_infra_admins"
CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)
CURRENT_USER_UPN=$(az ad signed-in-user show --query userPrincipalName -o tsv)

echo "Creating Entra ID group: ${INFRA_ADMIN_GROUP_NAME}"
# Check if group exists
GROUP_ID=$(az ad group list --filter "displayName eq '${INFRA_ADMIN_GROUP_NAME}'" --query "[0].id" -o tsv)

if [[ -z "${GROUP_ID}" ]]; then
    echo "Creating new Entra ID group for infrastructure administrators"
    GROUP_ID=$(az ad group create --display-name "${INFRA_ADMIN_GROUP_NAME}" \
        --mail-nickname "${PROJECT_NAME}InfraAdmins" \
        --description "Administrators for ${PROJECT_NAME} infrastructure" \
        --query "id" -o tsv)

    # Add current user as owner and member of the group
    echo "Adding current user (${CURRENT_USER_UPN}) as owner and member of the group"
    az ad group owner add --group "${INFRA_ADMIN_GROUP_NAME}" --owner-object-id "${CURRENT_USER_ID}"
    az ad group member add --group "${INFRA_ADMIN_GROUP_NAME}" --member-id "${CURRENT_USER_ID}"
else
    echo "Group ${INFRA_ADMIN_GROUP_NAME} already exists with ID: ${GROUP_ID}"
fi

if [[ -z "${GITHUB_REPO_OWNER}" || -z "${GITHUB_REPO_NAME}" ]]; then
    echo "WARNING: Could not automatically detect GitHub repository info."
    echo "For OIDC auth to work, manually set up the federated identity credentials."
else
    # Create a user-assigned managed identity for GitHub Actions
    IDENTITY_NAME="id-${PROJECT_NAME}-github"

    # Check if the identity already exists
    IDENTITY_EXISTS=$(az identity show --name "${IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP_NAME}" --query "name" --output tsv 2>/dev/null || echo "false")

    if [[ "${IDENTITY_EXISTS}" == "false" ]]; then
        echo "Creating managed identity for GitHub Actions..."
        az identity create --name "${IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP_NAME}" --location "${LOCATION}"
    fi

    # Get identity client ID and principal ID
    IDENTITY_CLIENT_ID=$(az identity show --name "${IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP_NAME}" --query "clientId" --output tsv)
    IDENTITY_PRINCIPAL_ID=$(az identity show --name "${IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP_NAME}" --query "principalId" --output tsv)

    # Assign Storage Blob Data Contributor role to the managed identity
    echo "Assigning Storage Blob Data Contributor role to managed identity..."
    STORAGE_ID=$(az storage account show --name "${STORAGE_ACCOUNT_NAME}" --resource-group "${RESOURCE_GROUP_NAME}" --query "id" --output tsv)

    az role assignment create \
        --assignee-object-id "${IDENTITY_PRINCIPAL_ID}" \
        --assignee-principal-type "ServicePrincipal" \
        --role "Storage Blob Data Contributor" \
        --scope "${STORAGE_ID}"

    # Set up federated identity credential for GitHub Actions
    echo "Setting up federated identity credential for GitHub Actions..." # Check if credential already exists
    CREDENTIAL_NAME="fc-github-${PROJECT_NAME}-${ENVIRONMENT}"
    CREDENTIAL_EXISTS=$(az identity federated-credential list --identity-name "${IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP_NAME}" --query "[?name=='${CREDENTIAL_NAME}'].name" --output tsv 2>/dev/null || echo "")

    if [[ -z "${CREDENTIAL_EXISTS}" ]]; then
        # Create credential for main branch and releases
        az identity federated-credential create \
            --name "${CREDENTIAL_NAME}" \
            --identity-name "${IDENTITY_NAME}" \
            --resource-group "${RESOURCE_GROUP_NAME}" \
            --issuer "https://token.actions.githubusercontent.com" \
            --subject "repo:${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}:environment:${ENVIRONMENT}" \
            --audiences "api://AzureADTokenExchange"
    fi

    # Output the values needed for GitHub Actions
    echo "===== VALUES FOR GITHUB REPOSITORY SECRETS ====="
    echo "AZURE_CLIENT_ID: ${IDENTITY_CLIENT_ID}"
    echo "AZURE_TENANT_ID: ${AZURE_TENANT_ID}"
    echo "AZURE_SUBSCRIPTION_ID: ${AZURE_SUBSCRIPTION_ID}"
    echo "================================================"
fi

# Create container using Azure CLI auth
echo "Creating blob container if it doesn't exist..."
# Check if container exists and create if needed
CONTAINER_EXISTS=$(az storage container exists --name "${CONTAINER_NAME}" --account-name "${STORAGE_ACCOUNT_NAME}" --auth-mode login --query "exists" --output tsv 2>/dev/null || echo "false")

if [[ "${CONTAINER_EXISTS}" == "false" ]]; then
    echo "Creating container: ${CONTAINER_NAME}"
    az storage container create --name "${CONTAINER_NAME}" --account-name "${STORAGE_ACCOUNT_NAME}" --auth-mode login
fi

# Now that the container is created, apply network restrictions
echo "Applying network restrictions to the storage account..."
az storage account update \
    --name "${STORAGE_ACCOUNT_NAME}" \
    --resource-group "${RESOURCE_GROUP_NAME}" \
    --default-action "Deny"

# Create backend configuration for specific environment
cat >backend-${ENVIRONMENT}.tfvars <<EOF
resource_group_name  = "${RESOURCE_GROUP_NAME}"
storage_account_name = "${STORAGE_ACCOUNT_NAME}"
container_name       = "${CONTAINER_NAME}"
key                  = "terraform.${ENVIRONMENT}.tfstate"
use_oidc             = true
use_azuread_auth     = true
subscription_id      = "${AZURE_SUBSCRIPTION_ID}"
tenant_id            = "${AZURE_TENANT_ID}"
EOF

echo "Backend configuration for ${ENVIRONMENT} created at backend-${ENVIRONMENT}.tfvars"
echo "Use 'tofu init -backend-config=backend-${ENVIRONMENT}.tfvars' to initialize backend"
