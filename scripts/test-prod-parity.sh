#!/bin/bash
# test-prod-parity.sh - Script to test parity between development and production environments

set -e

echo "=== Testing Production Environment Parity ==="
echo "This script helps identify differences between development and production environments"

# Create a temporary directory for test outputs
TEMP_DIR=$(mktemp -d)
trap 'rm -rf $TEMP_DIR' EXIT

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "Error: Docker is not running. Please start Docker and try again."
  exit 1
fi

# Function to run commands in the development and production environments and compare results
compare_environments() {
  local TEST_NAME=$1
  local COMMAND=$2
  
  echo -e "\n=== Testing: $TEST_NAME ==="
  
  echo "Running in development environment..."
  docker-compose exec -T backend bash -c "$COMMAND" > $TEMP_DIR/dev_output.txt 2>&1 || echo "Command failed in dev"
  
  echo "Running in production-like environment..."
  docker-compose run --rm backend-prod bash -c "$COMMAND" > $TEMP_DIR/prod_output.txt 2>&1 || echo "Command failed in prod"
  
  echo "Comparing outputs..."
  if diff -q $TEMP_DIR/dev_output.txt $TEMP_DIR/prod_output.txt > /dev/null; then
    echo "✅ PASS: Outputs match"
  else
    echo "❌ FAIL: Outputs differ"
    echo "--- Development output ---"
    cat $TEMP_DIR/dev_output.txt
    echo "--- Production output ---"
    cat $TEMP_DIR/prod_output.txt
    echo "--- End comparison ---"
  fi
}

# Make sure both environments are running
echo "Building and starting development and production environments..."
docker-compose up -d backend backend-prod

echo "Waiting for services to be healthy..."
sleep 10

# Test Python version and packages
compare_environments "Python Version" "python --version"
compare_environments "Installed Packages" "pip freeze | sort"

# Test environment variables
compare_environments "Environment Variables" "env | grep -v PASSWORD | sort"

# Test application health
compare_environments "Application Health" "curl -s http://localhost:8000/health"

# Test application functionality
compare_environments "API Functionality" "curl -s http://localhost:8000/api/v1/chat/mock_response"

echo -e "\n=== Environment Parity Test Complete ==="
echo "Review any failures above to address environment inconsistencies"

# Optional: Suggest solutions
echo -e "\nIf you found discrepancies, consider:"
echo "1. Adding missing packages to requirements.lock"
echo "2. Ensuring environment variables are consistently defined"
echo "3. Checking file permissions and user contexts"
echo "4. Reviewing dependency versions in both environments"