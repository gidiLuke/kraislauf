# kraislauf Documentation

This folder contains documentation for the kraislauf project.

## Contents

- [Architecture Overview](./architecture.md) - System architecture and component design
- [API Documentation](./api.md) - Backend API endpoints and usage

## Development Guidelines

### Code Style

- **Frontend**: Follow the Next.js and React best practices. Use TypeScript for type safety.
- **Backend**: Follow PEP 8 style guide for Python code. Use type hints.
- **Infrastructure**: Follow HashiCorp's style guide for OpenTofu/Terraform configurations.

### Git Workflow

1. Create feature branches from `main`
2. Name branches with descriptive prefixes:
   - `feature/` for new features
   - `fix/` for bug fixes
   - `docs/` for documentation changes
   - `refactor/` for code refactoring
3. Submit Pull Requests to `main`
4. Ensure CI passes before merging

### Environment Setup

See the root README.md for instructions on setting up the development environment using VS Code Dev Containers.
