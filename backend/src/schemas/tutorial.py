"""Tutorial-related request/response schemas."""

from pydantic import BaseModel, Field
from typing import List


class TutorialMetadata(BaseModel):
    """Tutorial metadata."""

    subject: str
    total_steps: int


class TutorialStep(BaseModel):
    """Individual tutorial step."""

    step_en: str
    step_de: str
    step_img: str  # base64 encoded image


class FullTutorialRequest(BaseModel):
    """Request to generate a full tutorial."""

    subject: str = Field(..., min_length=1, max_length=100, description="What to draw")


class FullTutorialResponse(BaseModel):
    """Response with complete tutorial."""

    success: str  # "true" or "false" as string
    metadata: TutorialMetadata
    steps: List[TutorialStep]
