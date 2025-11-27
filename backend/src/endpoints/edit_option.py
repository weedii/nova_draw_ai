"""
EditOption API endpoints.

Handles HTTP requests related to edit options.
This layer is responsible for:
- Accepting HTTP requests
- Validating request parameters
- Calling service layer for business logic
- Returning formatted HTTP responses
- Handling HTTP-level errors

Why this endpoint exists:
- Provides REST API interface for edit options
- Separates HTTP concerns from business logic
- Handles request/response serialization
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from src.database import get_db
from src.services.edit_option_service import EditOptionService
from src.services import AuthService
from src.models import User
from src.schemas import EditOptionsListResponse
from src.core.logger import logger

router = APIRouter(prefix="/api", tags=["edit-options"])


@router.get(
    "/edit-options/categories",
    response_model=dict,
    summary="Get all categories with edit options",
    description="Fetch all unique categories that have edit options available",
)
async def get_categories(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(AuthService.get_current_user),
):
    """
    Get all unique categories that have edit options.

    This endpoint is called when the app first loads to display available categories
    like "Animals", "Nature", etc.

    **Authentication Required:** User must be logged in.

    Returns:
        - success: bool - Whether the request was successful
        - data: List[str] - List of category names
        - count: int - Number of categories

    Raises:
        HTTPException 401: If user is not authenticated
        HTTPException 404: If no categories found
        HTTPException 500: If database error occurs
    """
    try:
        logger.info(f"User {current_user.email} fetching all categories")
        response = await EditOptionService.get_categories(db)
        return response

    except ValueError as e:
        logger.warning(f"Category not found: {str(e)}")
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to fetch categories: {str(e)}")
        raise HTTPException(
            status_code=500, detail=f"Failed to fetch categories: {str(e)}"
        )


@router.get(
    "/edit-options/categories/{category}/subjects",
    response_model=dict,
    summary="Get all subjects in a category",
    description="Fetch all unique subjects available in a specific category",
)
async def get_subjects_by_category(
    category: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(AuthService.get_current_user),
):
    """
    Get all subjects available in a specific category.

    This endpoint is called when a kid selects a category to see all available subjects
    (e.g., "dog", "cat", "bird" in the "Animals" category).

    **Authentication Required:** User must be logged in.

    Args:
        category: Category name (e.g., "Animals")

    Returns:
        - success: bool - Whether the request was successful
        - data: List[str] - List of subject names
        - count: int - Number of subjects

    Raises:
        HTTPException 401: If user is not authenticated
        HTTPException 404: If category not found or no subjects available
        HTTPException 500: If database error occurs
    """
    try:
        logger.info(
            f"User {current_user.email} fetching subjects for category '{category}'"
        )
        response = await EditOptionService.get_subjects_by_category(db, category)
        return response

    except ValueError as e:
        logger.warning(f"Subjects not found for category '{category}': {str(e)}")
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to fetch subjects for category '{category}': {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch subjects for category '{category}': {str(e)}",
        )


@router.get(
    "/edit-options/{category}/{subject}",
    response_model=EditOptionsListResponse,
    summary="Get edit options for a subject",
    description="Fetch all available edit options for a specific subject in a category",
)
async def get_edit_options_by_subject(
    category: str,
    subject: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(AuthService.get_current_user),
):
    """
    Get all edit options for a specific subject.

    This endpoint is called when a kid selects a subject and needs to see all available
    edit options (e.g., "Make it colorful", "Add sunglasses" for the "dog" subject).

    **Authentication Required:** User must be logged in.

    Args:
        category: Category name (e.g., "Animals")
        subject: Subject name (e.g., "dog")

    Returns:
        EditOptionsListResponse:
        - success: bool - Whether the request was successful
        - data: List[EditOptionRead] - List of edit options with full details
        - count: int - Number of edit options

    Raises:
        HTTPException 401: If user is not authenticated
        HTTPException 404: If subject not found or no options available
        HTTPException 500: If database error occurs

    Example:
        GET /api/edit-options/Animals/Dog
        Headers: Authorization: Bearer <token>
        Returns:
        {
            "success": true,
            "data": [
                {
                    "id": "uuid-1",
                    "tutorial_id": "tutorial-uuid",
                    "title_en": "Make it colorful",
                    "title_de": "Mach es farbig",
                    "description_en": "Add vibrant colors",
                    "description_de": "Füge lebendige Farben hinzu",
                    "prompt_en": "Make the drawing colorful...",
                    "prompt_de": "Mache die Zeichnung farbig...",
                    "icon": "🎨",
                    "created_at": "2024-01-01T00:00:00",
                    "updated_at": "2024-01-01T00:00:00"
                }
            ],
            "count": 1
        }
    """
    try:
        logger.info(
            f"User {current_user.email} fetching edit options for {category}/{subject}"
        )
        response = await EditOptionService.get_edit_options_by_subject(
            db, category, subject
        )
        return response

    except ValueError as e:
        logger.warning(f"Edit options not found for {category}/{subject}: {str(e)}")
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to fetch edit options for {category}/{subject}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch edit options for {category}/{subject}: {str(e)}",
        )
