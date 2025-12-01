from fastapi import APIRouter, HTTPException, UploadFile, File, Form, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from typing import Optional
from src.schemas import ImageProcessResponse, EditImageWithAudioResponse
from src.services.image_processing_service import ImageProcessingService
from src.services import AuthService
from src.models import User
from src.core.config import settings
from src.database import get_db
from src.core.logger import logger

router = APIRouter(prefix="/api", tags=["images"])

# Initialize services
image_processing_service = None
if settings.GOOGLE_API_KEY and settings.OPENAI_API_KEY:
    try:
        image_processing_service = ImageProcessingService()
    except Exception as e:
        logger.warning(f"Could not initialize image processing service: {e}")


@router.post("/edit-image", response_model=ImageProcessResponse)
async def edit_image(
    prompt: str = Form(
        ..., description="Processing instruction (e.g., 'make it alive')"
    ),
    subject: str = Form(
        None,
        description="What the child drew (e.g., 'dog', 'cat') - helps Gemini understand the drawing",
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
    drawing_id: str = Form(
        None,
        description="UUID of existing drawing to append edit to (optional for re-editing)",
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
            subject=subject,
            user_id=user_id,
            tutorial_id=UUID(tutorial_id) if tutorial_id else None,
            drawing_id=UUID(drawing_id) if drawing_id else None,
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
        logger.error(f"Failed to edit image: {str(e)}")
        # Handle validation errors
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException as e:
        logger.error(f"Failed to edit image: {str(e)}")
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
    subject: str = Form(
        None,
        description="What the child drew (e.g., 'dog', 'cat') - helps Gemini understand the drawing",
    ),
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
    drawing_id: str = Form(
        None,
        description="UUID of existing drawing to append edit to (optional for re-editing)",
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
        # Check if image service are available
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
            subject=subject,
            user_id=user_id,
            tutorial_id=UUID(tutorial_id) if tutorial_id else None,
            drawing_id=UUID(drawing_id) if drawing_id else None,
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


@router.post("/direct-upload", response_model=ImageProcessResponse)
async def direct_upload(
    subject: str = Form(
        ..., description="What did you draw? (e.g., 'train', 'dog', 'flower')"
    ),
    prompt: str = Form(
        ..., description="What should we do with it? (e.g., 'make it fly')"
    ),
    image: UploadFile = File(..., description="The drawing image file"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(AuthService.get_current_user),
):
    """
    Direct upload with text prompt: Upload any drawing and tell us what to do with it.

    This endpoint allows kids to upload drawings that don't fit existing tutorial categories.
    They specify what they drew (subject) and what they want done with it (text prompt).

    Flow:
    1. "What did you draw today?" → subject (e.g., "a train")
    2. Upload the drawing → image file
    3. "What should we do with it?" → prompt (text)

    **Authentication Required:** User must be logged in.
    """
    try:
        if not image_processing_service:
            raise HTTPException(
                status_code=503,
                detail="Image processing service not available. Please configure both Google and OpenAI API keys.",
            )

        # Validate image file type
        if not image.content_type or not image.content_type.startswith("image/"):
            raise HTTPException(
                status_code=400, detail="File must be an image (JPEG, PNG, etc.)"
            )

        image_data = await image.read()
        user_id = current_user.id

        result = await image_processing_service.process_direct_upload(
            db=db,
            subject=subject,
            user_id=user_id,
            image_data=image_data,
            prompt=prompt,
        )

        return ImageProcessResponse(
            success="true",
            prompt=result["prompt"],
            original_image_url=result["original_image_url"],
            edited_image_url=result["edited_image_url"],
            processing_time=result["processing_time"],
            drawing_id=result["drawing_id"],
            user_id=str(user_id),
        )

    except ValueError as e:
        logger.error(f"Direct upload validation error: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to process direct upload: {str(e)}")
        raise HTTPException(
            status_code=500, detail=f"Failed to process direct upload: {str(e)}"
        )


@router.post("/direct-upload-audio", response_model=ImageProcessResponse)
async def direct_upload_with_audio(
    subject: str = Form(
        ..., description="What did you draw? (e.g., 'train', 'dog', 'flower')"
    ),
    audio: UploadFile = File(
        ..., description="Voice recording of what to do with the drawing"
    ),
    image: UploadFile = File(..., description="The drawing image file"),
    language: str = Form(
        "en", description="Language for audio transcription: 'en' or 'de'"
    ),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(AuthService.get_current_user),
):
    """
    Direct upload with voice prompt: Upload any drawing and tell us what to do with it using voice.

    This endpoint allows kids to upload drawings that don't fit existing tutorial categories.
    They specify what they drew (subject) and speak what they want done with it (audio).

    Flow:
    1. "What did you draw today?" → subject (e.g., "a train")
    2. Upload the drawing → image file
    3. "What should we do with it?" → audio (voice recording)

    **Authentication Required:** User must be logged in.
    """
    try:
        if not image_processing_service:
            raise HTTPException(
                status_code=503,
                detail="Image processing service not available. Please configure both Google and OpenAI API keys.",
            )

        # Validate image file type
        if not image.content_type or not image.content_type.startswith("image/"):
            raise HTTPException(
                status_code=400, detail="File must be an image (JPEG, PNG, etc.)"
            )

        # Validate audio file type
        if not audio.content_type:
            raise HTTPException(
                status_code=400, detail="Could not determine audio file type"
            )

        image_data = await image.read()
        audio_data = await audio.read()
        user_id = current_user.id

        result = await image_processing_service.process_direct_upload(
            db=db,
            subject=subject,
            user_id=user_id,
            image_data=image_data,
            audio_data=audio_data,
            audio_filename=audio.filename or "audio.mp3",
            language=language,
        )

        return ImageProcessResponse(
            success="true",
            prompt=result["prompt"],
            original_image_url=result["original_image_url"],
            edited_image_url=result["edited_image_url"],
            processing_time=result["processing_time"],
            drawing_id=result["drawing_id"],
            user_id=str(user_id),
        )

    except ValueError as e:
        logger.error(f"Direct upload audio validation error: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to process direct upload with audio: {str(e)}")
        raise HTTPException(
            status_code=500, detail=f"Failed to process direct upload: {str(e)}"
        )
