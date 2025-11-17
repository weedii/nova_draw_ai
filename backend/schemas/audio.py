"""Audio-related schemas."""

from pydantic import BaseModel
from typing import Optional


class EditImageWithAudioResponse(BaseModel):
    """Response from audio-based image editing."""

    success: str  # "true" or "false" as string
    prompt: str  # Enhanced drawing prompt (matches ImageProcessResponse structure)
    result_image: str  # The enhanced prompt text (named for consistency with ImageProcessResponse)
    processing_time: Optional[float] = None
