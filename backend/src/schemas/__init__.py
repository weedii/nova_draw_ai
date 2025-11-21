"""
Pydantic schemas for API request/response validation.

This module exports all Pydantic models used for:
- API request validation
- API response serialization
- Data type hints

These are separate from SQLAlchemy ORM models (in models/).

Usage:
    from schemas import HealthResponse, FullTutorialRequest, RegisterRequest

    @app.get("/health", response_model=HealthResponse)
    async def health():
        return {"status": "healthy", "message": "API is running"}
"""

from .health import HealthResponse
from .tutorial import (
    FullTutorialRequest,
    FullTutorialResponse,
    TutorialMetadata,
    TutorialStep,
)
from .image import (
    ImageProcessRequest,
    ImageProcessResponse,
    EffectInfo,
    EffectsListResponse,
)
from .story import StoryRequest, StoryResponse
from .audio import EditImageWithAudioResponse
from .error import ErrorResponse, SessionInfo
from .auth import (
    RegisterRequest,
    LoginRequest,
    RefreshTokenRequest,
    UserResponse,
    AuthResponse,
    TokenRefreshResponse,
    MessageResponse,
)
from .edit_option import (
    EditOptionCreate,
    EditOptionUpdate,
    EditOptionRead,
    EditOptionsListResponse,
    EditOptionResponse,
)

__all__ = [
    "HealthResponse",
    "FullTutorialRequest",
    "FullTutorialResponse",
    "TutorialMetadata",
    "TutorialStep",
    "ImageProcessRequest",
    "ImageProcessResponse",
    "EffectInfo",
    "EffectsListResponse",
    "StoryRequest",
    "StoryResponse",
    "EditImageWithAudioResponse",
    "ErrorResponse",
    "SessionInfo",
    "RegisterRequest",
    "LoginRequest",
    "RefreshTokenRequest",
    "UserResponse",
    "AuthResponse",
    "TokenRefreshResponse",
    "MessageResponse",
    "EditOptionCreate",
    "EditOptionUpdate",
    "EditOptionRead",
    "EditOptionsListResponse",
    "EditOptionResponse",
]
