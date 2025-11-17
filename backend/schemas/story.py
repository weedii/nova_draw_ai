"""Story generation-related schemas."""

from pydantic import BaseModel, Field
from typing import Optional


class StoryRequest(BaseModel):
    """Request to generate a story from an image."""

    image: str = Field(..., description="Base64 encoded image to create story from")
    language: str = Field(
        ..., description="Language for story generation: 'en' or 'de'"
    )


class StoryResponse(BaseModel):
    """Response with generated story."""

    success: str  # "true" or "false" as string
    story: str  # Generated story text
    title: str  # Story title
    generation_time: Optional[float] = None
