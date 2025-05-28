# kraislauf System Architecture

## Overview

kraislauf is a modern web application designed to help users identify recyclable materials and learn proper recycling practices. The system is built as a monorepo with a clear separation between frontend, backend, and infrastructure components.

## Architecture Diagram

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│                 │      │                 │      │                 │
│   Azure Static  │      │  Azure Container│      │ Azure OpenAI    │
│    Web App      │◄────►│     App         │◄────►│   Service       │
│   (Frontend)    │      │   (Backend)     │      │                 │
│                 │      │                 │      │                 │
└─────────────────┘      └─────────────────┘      └─────────────────┘
        ▲                        ▲
        │                        │
        │                        │
        │                        │
┌───────▼────────────────────────▼──────────┐
│                                           │
│             GitHub Actions CI/CD          │
│                                           │
└───────────────────────────────────────────┘
        ▲
        │
        │
┌───────▼───────────────────────────────────┐
│                                           │
│          Developer Environment            │
│       (VS Code + Dev Container)           │
│                                           │
└───────────────────────────────────────────┘
```

## Key Components

### Frontend (Next.js + Tailwind CSS)

- Responsive UI for both desktop and mobile devices
- Chatbot interface for user interaction
- Image upload capability for recycling identification
- Deployed to Azure Static Web App

### Backend (FastAPI + LangChain)

- RESTful API endpoints for chat and image upload
- Integration with LangChain for AI processing
- Containerized with Docker
- Deployed to Azure Container App

### Infrastructure (OpenTofu + Azure)

- Infrastructure as Code (IaC) with OpenTofu
- Azure resources for hosting frontend and backend
- CI/CD with GitHub Actions

## Development Workflow

1. Developers work in a consistent environment using VS Code Dev Containers
2. Code changes trigger CI/CD pipelines in GitHub Actions
3. Automated testing and linting ensure code quality
4. Successful builds are deployed to Azure environments

## Security Considerations

- Authentication and authorization for admin functions
- Secure API communication between frontend and backend
- Azure resource access controls
- Environment-specific configuration management
