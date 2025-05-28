from pydantic import Field
from pydantic_settings import BaseSettings
from typing import List
import os


class Settings(BaseSettings):
    """Application settings."""

    # API configuration
    API_PREFIX: str = "/api"

    # CORS configuration
    CORS_ORIGINS: List[str] = Field(
        default=["http://localhost:3000",
                 "https://kraislauf.azurestaticwebapps.net"]
    )

    # Environment
    ENVIRONMENT: str = Field(default="development")

    # Logging
    LOG_LEVEL: str = Field(default="info")

    # Azure Configuration (placeholder)
    AZURE_OPENAI_API_KEY: str = Field(default="")
    AZURE_OPENAI_API_ENDPOINT: str = Field(default="")
    AZURE_OPENAI_API_VERSION: str = Field(default="2023-05-15")
    AZURE_OPENAI_DEPLOYMENT_NAME: str = Field(default="gpt-35-turbo")

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
