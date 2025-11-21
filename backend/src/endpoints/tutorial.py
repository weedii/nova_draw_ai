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
