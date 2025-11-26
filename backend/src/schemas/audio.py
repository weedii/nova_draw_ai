"""Audio-related schemas."""

from pydantic import BaseModel
from typing import Optional


class EditImageWithAudioResponse(BaseModel):
    """Response from audio-based image editing."""

    success: str  # "true" or "false" as string
    prompt: str  # Transcribed and enhanced prompt from audio
    original_image_url: Optional[str] = None  # URL of the original uploaded image
    edited_image_url: Optional[str] = None  # URL of the edited image
    processing_time: Optional[float] = None
    drawing_id: Optional[str] = None  # ID of the saved drawing in database
    user_id: Optional[str] = None  # ID of the user who created the drawing
