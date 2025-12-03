"""Story generation-related schemas."""

from pydantic import BaseModel, Field
from typing import Optional


class StoryRequest(BaseModel):
    """Request to generate a story from an image.

    Supports two modes:
    1. Upload image as base64 (image field provided)
    2. Use image URL from Spaces (image_url field provided)

    Stories are always generated in both English and German.
    """

    image: Optional[str] = Field(
        None,
        description="Base64 encoded image to create story from (optional if image_url provided)",
    )
    user_id: Optional[str] = Field(
        None,
        description="UUID of the user creating the story (optional, uses authenticated user)",
    )
    drawing_id: Optional[str] = Field(
        None, description="UUID of the drawing associated with this story"
    )
    image_url: Optional[str] = Field(
        None,
        description="URL of the image used for story generation (optional if image provided)",
    )


class StoryResponse(BaseModel):
    """Response with generated bilingual story."""

    success: str  # "true" or "false" as string
    title_en: str  # Story title in English
    title_de: str  # Story title in German
    story_text_en: str  # Generated story text in English
    story_text_de: str  # Generated story text in German
    generation_time: Optional[float] = None
    story_id: Optional[str] = None  # ID of the saved story in database
    image_url: Optional[str] = None  # URL of the image used for story generation
