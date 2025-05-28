# kraislauf

A modern application to help users identify recyclable materials and learn proper recycling practices.

## Project Structure

This monorepo contains the following components:

- **apps/frontend**: Next.js frontend application with Tailwind CSS and Chatbot UI
- **apps/backend**: FastAPI backend service with LangChain integration
- **infra**: Infrastructure as Code using OpenTofu for Azure deployment
- **docs**: Project documentation

## Getting Started

### Prerequisites

- Docker and Docker Compose
- VS Code with Dev Containers extension (recommended)

### Development

1. Clone this repository
2. Open in VS Code and reopen in container
3. Run the application:

```bash
docker-compose up
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
