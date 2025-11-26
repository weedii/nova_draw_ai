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
  Format: postgresql+asyncpg://user:password@host/dbname?ssl=require
- CORS_ORIGINS: Comma-separated list of allowed CORS origins (default: *)
- JWT_SECRET_KEY: Secret key for JWT token signing (required for production)
- JWT_ALGORITHM: JWT signing algorithm (default: HS256)
- ACCESS_TOKEN_EXPIRE_MINUTES: Access token expiry in minutes (default: 10080 = 7 days)
- REFRESH_TOKEN_EXPIRE_DAYS: Refresh token expiry in days (default: 30)

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
    # Format: postgresql+asyncpg://user:password@host/dbname?ssl=require
    # Note: asyncpg uses ?ssl=require (not ?sslmode=require)
    # Alembic will convert this to ?sslmode=require for psycopg2
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

    # JWT Authentication
    # Secret key for signing JWT tokens (should be a long random string in production)
    JWT_SECRET_KEY: str = os.getenv(
        "JWT_SECRET_KEY", "your-secret-key-change-in-production"
    )
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    # Access token expires in 7 days (10080 minutes) - kid-friendly, less frequent logins
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(
        os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "10080")
    )
    # Refresh token expires in 30 days
    REFRESH_TOKEN_EXPIRE_DAYS: int = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "30"))

    # Digitalocean Settings
    SPACES_KEY: str = os.getenv("SPACES_KEY")
    SPACES_SECRET: str = os.getenv("SPACES_SECRET")
    STORAGE_ENDPOINT_URL: str = os.getenv("STORAGE_ENDPOINT_URL")
    # Email Configuration
    MAIL_USERNAME: str = os.getenv("MAIL_USERNAME", "")
    MAIL_PASSWORD: str = os.getenv("MAIL_PASSWORD", "")
    MAIL_FROM: str = os.getenv("MAIL_FROM", "")
    MAIL_PORT: int = int(os.getenv("MAIL_PORT", "587"))
    MAIL_SERVER: str = os.getenv("MAIL_SERVER", "smtp.gmail.com")
    MAIL_STARTTLS: bool = os.getenv("MAIL_STARTTLS", "True").lower() == "true"
    MAIL_SSL_TLS: bool = os.getenv("MAIL_SSL_TLS", "False").lower() == "true"
    USE_CREDENTIALS: bool = os.getenv("USE_CREDENTIALS", "True").lower() == "true"
    VALIDATE_CERTS: bool = os.getenv("VALIDATE_CERTS", "True").lower() == "true"

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
