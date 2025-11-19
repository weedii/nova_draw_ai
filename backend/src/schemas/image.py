"""Image processing-related schemas."""

from pydantic import BaseModel, Field
from typing import Optional, List


class ImageProcessRequest(BaseModel):
    """Request for image processing."""

    prompt: Optional[str] = Field(
        None,
        min_length=1,
        max_length=500,
        description="Custom text prompt for image processing (e.g., 'make it alive')",
    )
    effect: Optional[str] = Field(
        None,
        description="Preset effect name (e.g., 'unicorn_magic', 'rainbow_blast'). If provided, this takes precedence over custom prompt.",
    )
    intensity: Optional[str] = Field(
        "medium",
        description="Effect intensity level: 'subtle', 'medium', or 'extreme'",
    )
    language: str = Field(
        "en",
        description="Language for effect descriptions: 'en' or 'de'",
    )


class ImageProcessResponse(BaseModel):
    """Response from image processing."""

    success: str  # "true" or "false" as string
    prompt: str
    result_image: str  # base64 encoded processed image
    processing_time: Optional[float] = None
    effect_used: Optional[str] = None  # The effect that was applied
    drawing_id: Optional[str] = None  # ID of the saved drawing in database
    user_id: Optional[str] = None  # ID of the user who created the drawing


class EffectInfo(BaseModel):
    """Information about an image effect."""

    id: str  # Effect identifier (e.g., "unicorn_magic")
    name_en: str  # English name
    name_de: str  # German name
    description_en: str  # English description
    description_de: str  # German description
    category: str  # Category (e.g., "magical", "artistic", "nature")
    emoji: str  # Fun emoji to represent the effect


class EffectsListResponse(BaseModel):
    """Response with list of available effects."""

    success: str
    effects: List[EffectInfo]
    total: int
