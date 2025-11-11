from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class HealthResponse(BaseModel):
    status: str
    message: str


class FullTutorialRequest(BaseModel):
    subject: str = Field(..., min_length=1, max_length=100, description="What to draw")


class TutorialMetadata(BaseModel):
    subject: str
    total_steps: int


class TutorialStep(BaseModel):
    step_en: str
    step_de: str
    step_img: str  # base64 encoded image


class FullTutorialResponse(BaseModel):
    success: str  # "true" or "false" as string
    metadata: TutorialMetadata
    steps: List[TutorialStep]


class SessionInfo(BaseModel):
    session_id: str
    subject: str
    created_at: str
    total_steps: int
    completed_steps: int


class ErrorResponse(BaseModel):
    success: bool = False
    error: str
    detail: Optional[str] = None


class ImageProcessRequest(BaseModel):
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
    success: str  # "true" or "false" as string
    prompt: str
    result_image: str  # base64 encoded processed image
    processing_time: Optional[float] = None
    effect_used: Optional[str] = None  # The effect that was applied


class EffectInfo(BaseModel):
    id: str  # Effect identifier (e.g., "unicorn_magic")
    name_en: str  # English name
    name_de: str  # German name
    description_en: str  # English description
    description_de: str  # German description
    category: str  # Category (e.g., "magical", "artistic", "nature")
    emoji: str  # Fun emoji to represent the effect


class EffectsListResponse(BaseModel):
    success: str
    effects: List[EffectInfo]
    total: int


class StoryRequest(BaseModel):
    image: str = Field(..., description="Base64 encoded image to create story from")
    language: str = Field(
        ..., description="Language for story generation: 'en' or 'de'"
    )


class StoryResponse(BaseModel):
    success: str  # "true" or "false" as string
    story: str  # Generated story text
    title: str  # Story title
    generation_time: Optional[float] = None


class AudioToPromptResponse(BaseModel):
    success: str  # "true" or "false" as string
    prompt: str  # Enhanced drawing prompt (matches ImageProcessResponse structure)
    result_image: str  # The enhanced prompt text (named for consistency with ImageProcessResponse)
    processing_time: Optional[float] = None
