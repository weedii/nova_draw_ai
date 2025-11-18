from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from schemas import StoryRequest, StoryResponse
from services.story_service import StoryService
from core.config import settings
from database import get_db
from models import Story

router = APIRouter(prefix="/api", tags=["stories"])

# Initialize service
story_service = None
if settings.OPENAI_API_KEY:
    try:
        story_service = StoryService()
    except Exception as e:
        print(f"Warning: Could not initialize story service: {e}")


@router.post("/create-story", response_model=StoryResponse)
async def create_story(request: StoryRequest, db: AsyncSession = Depends(get_db)):
    """
    Generate a children's story (ages 4-7) from an uploaded image.
    Supports English ('en') and German ('de') story generation.
    Saves the generated story to the database.
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

        # Prepare story data for database
        story_text_en = story if request.language == "en" else ""
        story_text_de = story if request.language == "de" else ""

        # Save story to database
        saved_story = await Story.create(
            db,
            user_id=UUID(request.user_id),
            drawing_id=UUID(request.drawing_id) if request.drawing_id else None,
            title=title,
            story_text_en=story_text_en,
            story_text_de=story_text_de,
            image_url=request.image_url or "",
            generation_time_ms=int(generation_time * 1000),
        )

        return StoryResponse(
            success="true",
            story=story,
            title=title,
            generation_time=generation_time,
            story_id=str(saved_story.id),
        )

    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Failed to generate story: {str(e)}"
        )
