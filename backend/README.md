# kraislauf Backend

FastAPI backend service for the kraislauf application. This service provides API endpoints for chat and image upload functionality.

## Getting Started

### Prerequisites

- Python 3.10+
- Docker and Docker Compose (recommended)

### Local Development

#### Using Docker (Recommended)

1. Start the backend service:

```bash
docker-compose up
```

2. The API will be available at <http://localhost:8000>

#### Direct Development

1. Create a virtual environment:

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Run the development server:

```bash
uvicorn app.main:app --reload
```

### API Documentation

Once the server is running, you can access the Swagger UI documentation at:

- <http://localhost:8000/docs>

The OpenAPI specification is available at:

- <http://localhost:8000/openapi.json>

## Project Structure

- `app/`: Application code
  - `api/`: API endpoints
  - `core/`: Core functionality (config, logging)
  - `models/`: Pydantic models
  - `services/`: Business logic and external service integrations
- `tests/`: Test cases

## Testing

Run tests with pytest:

```bash
pytest
```

## Configuration

Configuration is handled through environment variables, with defaults defined in `app/core/config.py`.

Key environment variables:

- `ENVIRONMENT`: Development or production mode
- `LOG_LEVEL`: Logging level (debug, info, etc.)
- `AZURE_OPENAI_API_KEY`: API key for Azure OpenAI (when implemented)

## Deployment

The backend is deployed as a container to Azure Container Apps. See the GitHub Actions workflow in `.github/workflows/deploy-backend.yml` for details.
