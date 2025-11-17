from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from schemas import ImageProcessResponse, EditImageWithAudioResponse
from services.image_processing_service import ImageProcessingService
from services.audio_service import AudioService
from core.config import settings

router = APIRouter(prefix="/api", tags=["images"])

# Initialize services
image_processing_service = None
if settings.GOOGLE_API_KEY and settings.OPENAI_API_KEY:
    try:
        image_processing_service = ImageProcessingService()
    except Exception as e:
        print(f"Warning: Could not initialize image processing service: {e}")

audio_service = None
if settings.OPENAI_API_KEY:
    try:
        audio_service = AudioService()
    except Exception as e:
        print(f"Warning: Could not initialize audio service: {e}")


@router.post("/edit-image", response_model=ImageProcessResponse)
async def edit_image(
    file: UploadFile = File(..., description="Image file to process"),
    prompt: str = Form(
        ..., description="Processing instruction (e.g., 'make it alive')"
    ),
):
    """
    Edit an uploaded image with AI using a text prompt.
    Supports prompts like 'make it alive', 'make it colorful', etc.
    """
    try:
        # Check if image processing service is available
        if not image_processing_service:
            raise HTTPException(
                status_code=503,
                detail="Image processing service not available. Please configure both Google and OpenAI API keys.",
            )

        # Validate file type
        if not file.content_type or not file.content_type.startswith("image/"):
            raise HTTPException(
                status_code=400, detail="File must be an image (JPEG, PNG, etc.)"
            )

        # Read image data
        image_data = await file.read()

        # Validate image
        if not image_processing_service.validate_image(image_data):
            raise HTTPException(
                status_code=400,
                detail="Invalid image or image too large (max 2048x2048)",
            )

        # Get image info for logging
        image_info = image_processing_service.get_image_info(image_data)
        print(f"Processing image: {image_info}")

        # Process the image
        result_base64, processing_time = image_processing_service.process_image(
            image_data, prompt
        )

        return ImageProcessResponse(
            success="true",
            prompt=prompt,
            result_image=result_base64,
            processing_time=processing_time,
        )

    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to edit image: {str(e)}")


@router.post("/edit-image-with-audio", response_model=EditImageWithAudioResponse)
async def edit_image_with_audio(
    image: UploadFile = File(..., description="Image file to edit"),
    audio: UploadFile = File(
        ...,
        description="Audio file (mp3, wav, m4a, aac, webm, ogg, flac) with editing instructions",
    ),
    language: str = Form(..., description="Language code: 'en' or 'de'"),
):
    """
    Edit an uploaded image using voice instructions from an audio file.

    Process:
    1. Transcribe audio to text using OpenAI Whisper
    2. Enhance the transcribed text into a detailed prompt
    3. Edit the image using the enhanced prompt
    4. Return the edited image

    Supports multiple audio formats: mp3, wav, m4a, aac, webm, ogg, flac
    Languages: English ('en') and German ('de')
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

        # Validate language parameter
        if language not in ["en", "de"]:
            raise HTTPException(
                status_code=400,
                detail="Invalid language. Please provide 'en' or 'de'.",
            )

        # Validate image file type
        if not image.content_type or not image.content_type.startswith("image/"):
            raise HTTPException(
                status_code=400, detail="Image file must be an image (JPEG, PNG, etc.)"
            )

        # Validate audio file type
        if not audio.content_type:
            raise HTTPException(
                status_code=400, detail="Could not determine audio file type"
            )

        # Read both files
        image_data = await image.read()
        audio_data = await audio.read()

        # Validate image
        if not image_processing_service.validate_image(image_data):
            raise HTTPException(
                status_code=400,
                detail="Invalid image or image too large (max 2048x2048)",
            )

        # Validate audio file
        if not audio_service.validate_audio_file(audio_data, audio.content_type):
            supported = audio_service.get_supported_formats()
            raise HTTPException(
                status_code=400,
                detail=f"Invalid audio file. Supported formats: {', '.join(supported['formats'])}. Max size: {supported['max_size_mb']}MB",
            )

        # Get file info for logging
        image_info = image_processing_service.get_image_info(image_data)
        audio_info = audio_service.get_audio_info(
            audio_data, audio.filename or "audio.mp3"
        )
        print(f"Processing image: {image_info}")
        print(f"Processing audio: {audio_info}")

        # Step 1: Transcribe audio to text
        transcribed_text, transcription_time = audio_service.transcribe_audio(
            audio_data, language, audio.filename or "audio.mp3"
        )

        # Step 2: Process the image with the transcribed text
        result_base64, processing_time = image_processing_service.process_image(
            image_data, transcribed_text
        )

        total_time = transcription_time + processing_time

        return EditImageWithAudioResponse(
            success="true",
            prompt=transcribed_text,  # Return the original transcribed text
            result_image=result_base64,
            processing_time=total_time,
        )

    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Failed to process audio and image: {str(e)}"
        )
