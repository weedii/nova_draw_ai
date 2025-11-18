from fastapi import APIRouter, HTTPException
from schemas import StoryRequest, StoryResponse
from services.story_service import StoryService
from core.config import settings

router = APIRouter(prefix="/api", tags=["stories"])

# Initialize service
story_service = None
if settings.OPENAI_API_KEY:
    try:
        story_service = StoryService()
    except Exception as e:
        print(f"Warning: Could not initialize story service: {e}")


@router.post("/create-story", response_model=StoryResponse)
async def create_story(request: StoryRequest):
    """
    Generate a children's story (ages 4-7) from an uploaded image.
    Supports English ('en') and German ('de') story generation.
    """
    try:
        # Check if story service is available
        if not story_service:
            raise HTTPException(
                status_code=503,
                detail="Story generation service not available. Please configure OpenAI API key.",
            )

        # Validate the base64 image
        if not story_service.validate_image_base64(request.image):
            raise HTTPException(
                status_code=400,
                detail="Invalid image data. Please provide a valid base64 encoded image.",
            )

        # Validate language parameter
        if request.language not in ["en", "de"]:
            raise HTTPException(
                status_code=400,
                detail="Invalid language. Please provide 'en' or 'de'.",
            )

        # Generate the story with the specified language
        title, story, generation_time = story_service.generate_story(
            request.image, request.language
        )

        return StoryResponse(
            success="true",
            story=story,
            title=title,
            generation_time=generation_time,
        )

    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Failed to generate story: {str(e)}"
        )
