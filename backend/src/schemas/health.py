"""Health check response schema."""

from pydantic import BaseModel


class HealthResponse(BaseModel):
    """API health check response."""

    status: str
    message: str
