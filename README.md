# kraislauf

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

A modern application to help users identify recyclable materials and learn proper recycling practices.

## Project Structure

This monorepo contains the following components:

- **apps/frontend**: Next.js frontend application with Tailwind CSS and Chatbot UI
- **apps/backend**: FastAPI backend service with LangChain integration
- **infra**: Infrastructure as Code using OpenTofu for Azure deployment
- **docs**: Project documentation

## Contributing

### Prerequisites

- Docker and Docker Compose
- VS Code with Dev Containers extension (recommended)
- Git
- Azure CLI (for cloud deployment)
- GitHub CLI (for repository management)

### Development with DevContainer

1. Clone this repository
2. Open in VS Code and reopen in container when prompted, or run the "Remote-Containers: Reopen in Container" command

The DevContainer includes all necessary tools:

- Python 3.13 with uv package manager
- Node.js 20 with pnpm
- OpenTofu (Terraform alternative)
- Azure CLI
- GitHub CLI
- Pre-commit hooks

For a quick setup, you can use the provided script:

```bash
# From the root of the repository
./scripts/setup-dev-environment.sh
```

This script will check prerequisites, install necessary VS Code extensions, and open the project in VS Code with DevContainer support.

#### Verifying Your Development Environment

When inside the DevContainer, all necessary tools are pre-installed and ready to use. The Docker setup follows a multi-stage approach with stages for:

- Development environment (IDE)
- Testing and linting (CI)
- Frontend build
- Backend runtime

#### Rebuilding the DevContainer

If you need to rebuild the development container after updating the Dockerfile or devcontainer.json:

```bash
# From the root of the repository
./scripts/rebuild-devcontainer.sh
```

#### Available Dev Commands

Once inside the DevContainer, you can use these commands:

```bash
# Start the frontend development server
cd frontend && pnpm dev

# Start the backend development server
cd backend && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Run backend tests
cd backend && pytest

# Run frontend tests
cd frontend && pnpm test

# Start the entire stack with Docker Compose
docker-compose up --build
```

You can also use VS Code tasks to execute these commands. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS) and type "Run Task" to see available tasks.

### Local Development without DevContainer

If you prefer not to use DevContainers, you can run the application using Docker Compose:

```bash
# Start the entire stack
docker-compose up

# Or build and start with fresh containers
docker-compose up --build
```

The frontend will be available at <http://localhost:3000> and the backend at <http://localhost:8000>.

The multi-stage Dockerfile allows for:

- Testing and linting in CI/CD workflows
- Building the frontend in a containerized environment
- Running the backend in Azure Container Apps

The frontend is deployed directly to Azure Static Web Apps after being built.

### GitOps Flow

#### Branching & PRs

- Trunk-based development: single `main` branch, always deployable
- Short-lived feature branches off `main` (naming convention: `<issue-number>-short-description`)
- Enforced PR reviews and status checks (lint, tests, security)

#### CI/CD

- Automated builds and tests on PRs
- Infrastructure deployment via github actions is automatically triggered on merges to `main`
- Infrastructure deployment to the dev environment can be manually triggered via github actions
- Automated deployment to production is triggered on merges to `main` after successful tests
- Automated deployment to a feature environment is triggered by for PRs on feature branches

## License

This project is licensed under the Apache License, Version 2.0 - see the [LICENSE](./LICENSE) file for details.
