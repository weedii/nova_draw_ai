from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from schemas import (
    FullTutorialRequest,
    FullTutorialResponse,
    TutorialStep,
    TutorialMetadata,
)
from database import get_db
from repositories import TutorialRepository
from models import TutorialStep as TutorialStepModel

router = APIRouter(prefix="/api", tags=["tutorials"])


@router.post("/generate-tutorial", response_model=FullTutorialResponse)
async def generate_tutorial_local(
    request: FullTutorialRequest, db: AsyncSession = Depends(get_db)
):
    """
    Fetch a drawing tutorial from the Neon database by subject.
    Returns tutorial metadata and steps with base64 encoded images.
    """
    try:
        # Get tutorial by subject from repository
        tutorial = await TutorialRepository.find_by_subject(db, request.subject)

        if not tutorial:
            # If subject not found, provide helpful error
            raise HTTPException(
                status_code=404,
                detail=f"Subject '{request.subject}' not found in database. Please check the available subjects.",
            )

        # Get tutorial steps from database
        steps = await TutorialRepository.get_tutorials_with_steps(db)

        # Filter steps for this tutorial
        tutorial_steps_data = [s for s in steps if s.tutorial_id == tutorial.id]

        # Convert to the expected response format
        tutorial_steps = []
        for step_data in tutorial_steps_data:
            tutorial_steps.append(
                TutorialStep(
                    step_en=step_data.instruction_en,
                    step_de=step_data.instruction_de,
                    step_img=step_data.image_url,  # URL or base64
                )
            )

        return FullTutorialResponse(
            success="true",
            metadata=TutorialMetadata(
                subject=tutorial.subject,
                total_steps=tutorial.total_steps,
            ),
            steps=tutorial_steps,
        )

    except HTTPException:
        # Re-raise HTTP exceptions (like 404)
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Failed to load tutorial from database: {str(e)}"
        )
