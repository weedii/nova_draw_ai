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
    prompt: str = Field(
        ...,
        min_length=1,
        max_length=500,
        description="Text prompt for image processing (e.g., 'make it alive')",
    )


class ImageProcessResponse(BaseModel):
    success: str  # "true" or "false" as string
    prompt: str
    result_image: str  # base64 encoded processed image
    processing_time: Optional[float] = None
