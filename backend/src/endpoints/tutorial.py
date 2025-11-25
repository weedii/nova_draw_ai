from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from src.schemas import FullTutorialRequest, FullTutorialResponse
from src.database import get_db
from src.services.tutorial_service import TutorialService
from src.services import AuthService
from src.models import User
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["tutorials"])


@router.post("/generate-tutorial", response_model=FullTutorialResponse)
async def generate_tutorial_local(
    request: FullTutorialRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(AuthService.get_current_user),
):
    """
    Fetch a random drawing tutorial from the database by subject.
    Returns tutorial metadata and all its steps with images.

    **Authentication Required:** User must be logged in.
    """
    try:
        # Delegate all business logic to the service layer
        response = await TutorialService.get_tutorial_by_subject(db, request.subject)
        return response

    except ValueError as e:
        # Handle validation errors
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to load tutorial from database: {str(e)}")
        raise HTTPException(
            status_code=500, detail=f"Failed to load tutorial from database: {str(e)}"
        )


@router.get("/categories-with-drawings")
async def get_categories_with_drawings(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(AuthService.get_current_user),
):
    """
    Get all categories with their nested drawings.

    Returns all available drawing categories with complete drawing information
    for each category. Each category includes its drawings with metadata like
    total steps, thumbnail URL, and descriptions in both English and German.

    **Authentication Required:** User must be logged in.

    Returns:
        AllCategoriesWithDrawingsResponse:
        - success: bool - Whether the request was successful
        - data: List[CategoryWithNestedDrawingsResponse] - Categories with drawings
        - count: int - Number of categories

    Raises:
        HTTPException 401: If user is not authenticated
        HTTPException 404: If no categories/tutorials found
        HTTPException 500: If database error occurs

    Example:
        GET /api/categories-with-drawings
        Headers: Authorization: Bearer <token>
        Returns:
        {
            "success": true,
            "data": [
                {
                    "title_en": "Animals",
                    "title_de": "Tiere",
                    "description_en": null,
                    "description_de": null,
                    "icon": "🎨",
                    "drawings": [
                        {
                            "name_en": "dog",
                            "name_de": "dog",
                            "emoji": "✏️",
                            "total_steps": 4,
                            "thumbnail_url": "https://...",
                            "description_en": "...",
                            "description_de": "..."
                        }
                    ]
                }
            ],
            "count": 3
        }
    """

    try:
        logger.info(f"User {current_user.email} fetching all categories with drawings")
        response = await TutorialService.get_all_categories_with_nested_drawings(db)
        return response

    except ValueError as e:
        logger.warning(f"Categories not found: {str(e)}")
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to fetch categories with drawings: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch categories with drawings: {str(e)}",
        )


@router.get("/categories/{category}/drawings")
async def get_drawings_by_category(
    category: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(AuthService.get_current_user),
):
    """
    Get all drawings for a specific category.

    Returns all available drawings/subjects within a specific category.
    Useful as a fallback endpoint if categories are already loaded and
    only drawings for a specific category are needed.

    **Authentication Required:** User must be logged in.

    Args:
        category: Category name (e.g., "Animals", "Nature")

    Returns:
        List[TutorialDrawingResponse]: List of drawings in the category

    Raises:
        HTTPException 401: If user is not authenticated
        HTTPException 404: If category not found or no drawings available
        HTTPException 500: If database error occurs

    Example:
        GET /api/categories/Animals/drawings
        Headers: Authorization: Bearer <token>
        Returns:
        [
            {
                "name_en": "dog",
                "name_de": "dog",
                "emoji": "✏️",
                "total_steps": 4,
                "thumbnail_url": "https://...",
                "description_en": "...",
                "description_de": "..."
            }
        ]
    """

    try:
        logger.info(
            f"User {current_user.email} fetching drawings for category '{category}'"
        )
        drawings = await TutorialService.get_all_drawings_for_category(db, category)
        return drawings

    except ValueError as e:
        logger.warning(f"Drawings not found for category '{category}': {str(e)}")
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to fetch drawings for category '{category}': {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch drawings for category '{category}': {str(e)}",
        )
