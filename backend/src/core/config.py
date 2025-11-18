"""
Application configuration and settings management.

This module loads all application settings from environment variables using Pydantic.
Settings are read from the .env file in the project root.

Environment variables:
- OPENAI_API_KEY: OpenAI API key for text generation (optional)
- GOOGLE_API_KEY: Google Gemini API key for image generation (optional)
- HOST: Server host (default: 0.0.0.0)
- PORT: Server port (default: 8000)
- DATABASE_URL: Neon PostgreSQL connection string (required for production)
  Format: postgresql+asyncpg://user:password@host/dbname?sslmode=require
- CORS_ORIGINS: Comma-separated list of allowed CORS origins (default: *)

Usage:
    from core.config import settings

    print(settings.DATABASE_URL)
    print(settings.HOST)
    print(settings.PORT)
"""

import os
from pathlib import Path
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables.

    All settings are loaded from the .env file in the project root.
    Use case_sensitive=False to allow both uppercase and lowercase env vars.
    """

    # API Keys (optional - not needed for local database)
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    GOOGLE_API_KEY: str = os.getenv("GOOGLE_API_KEY", "")

    # Server Configuration
    # Default to 0.0.0.0:8000 for Docker compatibility
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))

    # Database Configuration
    # Format: postgresql+asyncpg://user:password@host/dbname?sslmode=require
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
    )

    # CORS Origins
    # Comma-separated list of allowed origins. Use "*" for development only.
    CORS_ORIGINS: str = os.getenv("CORS_ORIGINS", "*")

    # File Storage
    storage_path: Path = Path("storage/drawings")
    max_steps: int = 10
    min_steps: int = 3

    # Encryption
    ENCRYPTION_KEY: str = os.getenv("ENCRYPTION_KEY", "")

    class Config:
        """Pydantic configuration"""

        env_file = "../.env"
        case_sensitive = False
        extra = "ignore"  # Ignore extra fields in .env file

    def __init__(self, **kwargs):
        """Initialize settings and create storage directory if needed"""
        super().__init__(**kwargs)
        # Create storage directory if it doesn't exist
        self.storage_path.mkdir(parents=True, exist_ok=True)


# Global settings instance
# Import this in your modules to access configuration
settings = Settings()
