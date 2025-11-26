from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from src.schemas import StoryRequest, StoryResponse
from src.services.story_service import StoryService
from src.services import AuthService
from src.models import User
from src.core.config import settings
from src.database import get_db
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["stories"])

# Initialize service
story_service = None
if settings.OPENAI_API_KEY:
    try:
        story_service = StoryService()
    except Exception as e:
        logger.warning(f"Could not initialize story service: {e}")


@router.post("/create-story", response_model=StoryResponse)
async def create_story(
    request: StoryRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(AuthService.get_current_user),
):
    """
    Generate a children's story (ages 4-7) from an image.
    Supports two modes:
    1. Upload image as base64 (request.image provided)
    2. Use image URL from Spaces (request.image_url provided)

    Supports English ('en') and German ('de') story generation.
    Saves the generated story to the database and links it to a drawing if drawing_id provided.

    **Authentication Required:** User must be logged in.
    """

    try:
        # Check if story service is available
        if not story_service:
            raise HTTPException(
                status_code=503,
                detail="Story generation service not available. Please configure OpenAI API key.",
            )

        # Use authenticated user's ID instead of request user_id
        # This ensures users can only create stories for themselves
        user_id = current_user.id

        # Delegate all business logic to the service layer
        result = await story_service.create_story(
            db=db,
            image_base64=request.image,
            language=request.language,
            user_id=user_id,
            drawing_id=UUID(request.drawing_id) if request.drawing_id else None,
            image_url=request.image_url or "",
        )

        return StoryResponse(
            success="true",
            story=result["story"],
            title=result["title"],
            generation_time=result["generation_time"],
            story_id=result["story_id"],
            image_url=request.image_url,
        )

    except ValueError as e:
        # Handle validation errors
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Failed to generate story: {str(e)}")
        raise HTTPException(
            status_code=500, detail=f"Failed to generate story: {str(e)}"
        )
