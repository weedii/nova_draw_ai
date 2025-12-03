from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from src.schemas import StoryRequest, StoryResponse
from src.services.story_service import StoryService
from src.services import AuthService
from src.models import User
from src.core.config import settings
from src.database import get_db
from src.core.logger import logger

router = APIRouter(prefix="/api", tags=["stories"])


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
        # Initialize story service
        story_service = StoryService()

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


@router.get("/drawings/{drawing_id}/stories")
async def get_story_for_image(
    drawing_id: UUID,
    image_url: str = Query(..., description="URL of the image"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(AuthService.get_current_user),
):
    """
    Get a specific story for a drawing and image URL.

    Returns the story if it exists, or null if no story has been created for this image yet.

    **Authentication Required:** User must be logged in.

    Query Parameters:
    - image_url: URL of the image

    Returns:
    - Story details if found, or null if not found
    """

    try:
        logger.info(f"📖 Fetching story for drawing {drawing_id} and image {image_url}")

        # Initialize service
        story_service = StoryService()

        # Delegate to service layer
        result = await story_service.get_story_for_image(
            db=db,
            drawing_id=drawing_id,
            image_url=image_url,
            user_id=current_user.id,
        )

        logger.info(f"✅ Retrieved story for drawing {drawing_id}")

        return {"success": True, "story": result}

    except ValueError as e:
        logger.warning(f"⚠️ {str(e)}")
        if "permission" in str(e).lower():
            raise HTTPException(status_code=403, detail=str(e))
        else:
            raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"❌ Failed to fetch story: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch story: {str(e)}")
