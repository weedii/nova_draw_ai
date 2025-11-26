from fastapi import APIRouter, HTTPException, UploadFile, File, Form, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from src.schemas import ImageProcessResponse, EditImageWithAudioResponse
from src.services.image_processing_service import ImageProcessingService
from src.services.audio_service import AudioService
from src.services import AuthService
from src.models import User
from src.core.config import settings
from src.database import get_db
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["images"])

# Initialize services
image_processing_service = None
if settings.GOOGLE_API_KEY and settings.OPENAI_API_KEY:
    try:
        image_processing_service = ImageProcessingService()
    except Exception as e:
        logger.warning(f"Could not initialize image processing service: {e}")

audio_service = None
if settings.OPENAI_API_KEY:
    try:
        audio_service = AudioService()
    except Exception as e:
        logger.warning(f"Could not initialize audio service: {e}")


@router.post("/edit-image", response_model=ImageProcessResponse)
async def edit_image(
    prompt: str = Form(
        ..., description="Processing instruction (e.g., 'make it alive')"
    ),
    image: UploadFile = File(
        None, description="Image file to process (optional if image_url is provided)"
    ),
    image_url: str = Form(
        None,
        description="URL of existing image from Spaces to edit (optional if file is provided)",
    ),
    tutorial_id: str = Form(
        None, description="UUID of the tutorial associated with this drawing"
    ),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(AuthService.get_current_user),
):
    """
    Edit an image with AI using a text prompt.
    Supports two modes:
    1. Upload a new image file to process
    2. Provide a URL of an existing image from Spaces to re-edit

    Supports prompts like 'make it alive', 'make it colorful', etc.
    Saves the edited image to the database.

    **Authentication Required:** User must be logged in.
    """

    try:
        # Check if image processing service is available
        if not image_processing_service:
            raise HTTPException(
                status_code=503,
                detail="Image processing service not available. Please configure both Google and OpenAI API keys.",
            )

        # Validate that either image file or image_url is provided
        if not image and not image_url:
            raise HTTPException(
                status_code=400,
                detail="Either 'image file' or 'image_url' must be provided",
            )

        image_data = None

        # If image file is provided, read and validate it
        if image:
            # Validate file type
            if not image.content_type or not image.content_type.startswith("image/"):
                raise HTTPException(
                    status_code=400, detail="File must be an image (JPEG, PNG, etc.)"
                )

            # Read image data
            image_data = await image.read()

        # Use authenticated user's ID
        user_id = current_user.id

        # Delegate all business logic to the service layer
        result = await image_processing_service.edit_image_with_prompt(
            db=db,
            prompt=prompt,
            user_id=user_id,
            tutorial_id=UUID(tutorial_id) if tutorial_id else None,
            image_data=image_data,
            image_url=image_url,
        )

        return ImageProcessResponse(
            success="true",
            prompt=prompt,
            original_image_url=result["original_image_url"],
            edited_image_url=result["edited_image_url"],
            processing_time=result["processing_time"],
            drawing_id=result["drawing_id"],
            user_id=str(user_id),
        )

    except ValueError as e:
        # Handle validation errors
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Failed to edit image: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to edit image: {str(e)}")


@router.post("/edit-image-with-audio", response_model=EditImageWithAudioResponse)
async def edit_image_with_audio(
    audio: UploadFile = File(
        ...,
        description="Audio file (mp3, wav, m4a, aac, webm, ogg, flac) with editing instructions",
    ),
    language: str = Form(..., description="Language code: 'en' or 'de'"),
    image: UploadFile = File(
        None, description="Image file to edit (optional if image_url is provided)"
    ),
    image_url: str = Form(
        None,
        description="URL of existing image from Spaces to edit (optional if image is provided)",
    ),
    tutorial_id: str = Form(
        None, description="UUID of the tutorial associated with this drawing"
    ),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(AuthService.get_current_user),
):
    """
    Edit an image using voice instructions from an audio file.
    Supports two modes:
    1. Upload a new image file to process
    2. Provide a URL of an existing image from Spaces to re-edit

    Process:
    1. Transcribe audio to text using OpenAI Whisper
    2. Enhance the transcribed text into a detailed prompt
    3. Edit the image using the enhanced prompt
    4. Save the edited image to the database
    5. Return the edited image

    Supports multiple audio formats: mp3, wav, m4a, aac, webm, ogg, flac
    Languages: English ('en') and German ('de')

    **Authentication Required:** User must be logged in.
    """

    try:
        # Check if both services are available
        if not audio_service:
            raise HTTPException(
                status_code=503,
                detail="Audio transcription service not available. Please configure OpenAI API key.",
            )

        if not image_processing_service:
            raise HTTPException(
                status_code=503,
                detail="Image processing service not available. Please configure both Google and OpenAI API keys.",
            )

        # Validate that either image or image_url is provided
        if not image and not image_url:
            raise HTTPException(
                status_code=400,
                detail="Either 'image' or 'image_url' must be provided",
            )

        # Validate audio file type
        if not audio.content_type:
            raise HTTPException(
                status_code=400, detail="Could not determine audio file type"
            )

        image_data = None

        # If image file is provided, read and validate it
        if image:
            # Validate image file type
            if not image.content_type or not image.content_type.startswith("image/"):
                raise HTTPException(
                    status_code=400,
                    detail="Image file must be an image (JPEG, PNG, etc.)",
                )

            # Read image data
            image_data = await image.read()

        # Read audio data
        audio_data = await audio.read()

        # Use authenticated user's ID
        user_id = current_user.id

        # Delegate all business logic to the service layer
        result = await image_processing_service.edit_image_with_audio(
            db=db,
            audio_data=audio_data,
            audio_filename=audio.filename or "audio.mp3",
            language=language,
            user_id=user_id,
            tutorial_id=UUID(tutorial_id) if tutorial_id else None,
            audio_service=audio_service,
            image_data=image_data,
            image_url=image_url,
        )

        return EditImageWithAudioResponse(
            success="true",
            prompt=result["prompt"],
            original_image_url=result["original_image_url"],
            edited_image_url=result["edited_image_url"],
            processing_time=result["processing_time"],
            drawing_id=result["drawing_id"],
            user_id=str(user_id),
        )

    except ValueError as e:
        # Handle validation errors
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Failed to process audio and image: {str(e)}")
        raise HTTPException(
            status_code=500, detail=f"Failed to process audio and image: {str(e)}"
        )
