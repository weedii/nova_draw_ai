import os
from pathlib import Path
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""

    # API Keys
    openai_api_key: str
    google_api_key: str

    # Server Configuration
    host: str = "0.0.0.0"
    port: int = 8000

    # CORS Origins
    cors_origins: str = "*"

    # File Storage
    storage_path: Path = Path("storage/drawings")
    max_steps: int = 10
    min_steps: int = 3

    class Config:
        env_file = "../.env"
        case_sensitive = False
        extra = "ignore"  # Ignore extra fields in .env file

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Create storage directory if it doesn't exist
        self.storage_path.mkdir(parents=True, exist_ok=True)


# Global settings instance
settings = Settings()
