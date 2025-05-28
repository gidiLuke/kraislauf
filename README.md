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

### Development

1. Clone this repository
2. Open in VS Code and reopen in container

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
