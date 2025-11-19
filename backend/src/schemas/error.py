"""Error and session-related schemas."""

from pydantic import BaseModel
from typing import Optional


class ErrorResponse(BaseModel):
    """Standard error response."""

    success: bool = False
    error: str
    detail: Optional[str] = None


class SessionInfo(BaseModel):
    """Session information."""

    session_id: str
    subject: str
    created_at: str
    total_steps: int
    completed_steps: int
