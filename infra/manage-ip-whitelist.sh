#!/bin/bash
# manage-ip-whitelist.sh - Manage IP whitelist for the Azure Storage Account
# Usage: ./manage-ip-whitelist.sh [add|remove|list|show-current] [environment]

set -e

# Ensure environment parameter is provided
ENVIRONMENT=${2:-}
if [ -z "$ENVIRONMENT" ]; then
    echo "Error: Environment parameter is required."
    echo "Usage: ./manage-ip-whitelist.sh [add|remove|list|show-current] [dev|prd]"
    exit 1
fi

# Validate environment parameter
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prd" ]]; then
    echo "Invalid environment: $ENVIRONMENT. Must be either 'dev' or 'prd'."
    exit 1
fi

# Source the environment file to get the storage account name
if [ -f .env.infra.${ENVIRONMENT} ]; then
    source .env.infra.${ENVIRONMENT}
else
    echo "Error: .env.infra.${ENVIRONMENT} file not found. Run ./backend-config.sh ${ENVIRONMENT} first."
    exit 1
fi

RESOURCE_GROUP_NAME="rg-kraislauf-infra"
ACTION=${1:-"list"}

# Function to get current public IP
get_current_ip() {
    curl -s https://api.ipify.org
}

# Check if the storage account name is available
if [ -z "$STORAGE_ACCOUNT_NAME" ]; then
    echo "Error: STORAGE_ACCOUNT_NAME not found in .env.infra.${ENVIRONMENT}"
    exit 1
fi

# Validate the action parameter
if [[ "$ACTION" != "add" && "$ACTION" != "remove" && "$ACTION" != "list" && "$ACTION" != "show-current" ]]; then
    echo "Invalid action: $ACTION. Must be one of: add, remove, list, show-current."
    exit 1
fi

# Execute the requested action
case "$ACTION" in
"add")
    CURRENT_IP=$(get_current_ip)
    echo "Adding your current IP ($CURRENT_IP) to the allowed list..."
    az storage account network-rule add \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --ip-address "$CURRENT_IP"
    echo "IP added successfully."
    ;;
"remove")
    IP_TO_REMOVE=${2:-$(get_current_ip)}
    echo "Removing IP $IP_TO_REMOVE from the allowed list..."
    az storage account network-rule remove \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --ip-address "$IP_TO_REMOVE"
    echo "IP removed successfully."
    ;;
"list")
    echo "Currently allowed IPs:"
    az storage account network-rule list \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --query "ipRules[].ipAddressOrRange" \
        --output table
    ;;
"show-current")
    CURRENT_IP=$(get_current_ip)
    echo "Your current public IP address is: $CURRENT_IP"
    ;;
esac

# Check if the current IP is in the allowed list
if [[ "$ACTION" == "add" || "$ACTION" == "list" ]]; then
    CURRENT_IP=$(get_current_ip)
    IP_ALLOWED=$(az storage account network-rule list \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --query "ipRules[?contains(ipAddressOrRange, '$CURRENT_IP')].ipAddressOrRange" \
        --output tsv)

    if [[ -z "$IP_ALLOWED" ]]; then
        echo "WARNING: Your current IP ($CURRENT_IP) is NOT in the allowed list."
        echo "Run './manage-ip-whitelist.sh add ${ENVIRONMENT}' to add it."
    else
        echo "Your current IP ($CURRENT_IP) is already in the allowed list."
    fi
fi
