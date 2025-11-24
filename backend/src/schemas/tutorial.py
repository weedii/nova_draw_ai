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


class TutorialDrawingResponse(BaseModel):
    """Schema for drawing/subject data in category responses."""

    name_en: str
    name_de: str
    emoji: str
    total_steps: int
    thumbnail_url: str | None = None
    description_en: str | None = None
    description_de: str | None = None


class CategoryWithNestedDrawingsResponse(BaseModel):
    """Schema for category with nested drawings."""

    title_en: str
    title_de: str
    description_en: str | None = None
    description_de: str | None = None
    emoji: str
    color: str
    drawings: List[TutorialDrawingResponse]


class AllCategoriesWithDrawingsResponse(BaseModel):
    """Response schema for all categories with their nested drawings."""

    success: bool
    data: List[CategoryWithNestedDrawingsResponse]
    count: int
