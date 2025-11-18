from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from src.schemas import (
    FullTutorialRequest,
    FullTutorialResponse,
    TutorialStep,
    TutorialMetadata,
)
from src.database import get_db
from src.repositories import TutorialRepository
from src.models import Tutorial, TutorialStep as TutorialStepModel
import logging

router = APIRouter(prefix="/api", tags=["tutorials"])


@router.post("/generate-tutorial", response_model=FullTutorialResponse)
async def generate_tutorial_local(
    request: FullTutorialRequest, db: AsyncSession = Depends(get_db)
):
    """
    Fetch a random drawing tutorial from the database by subject.
    Returns tutorial metadata and all its steps with images.

    Flow:
    1. Find all tutorials with the given subject
    2. Select a random one
    3. Load all steps for that tutorial
    4. Return tutorial metadata and steps
    """
    try:
        # Step 1: Find a random tutorial by subject
        tutorial = await TutorialRepository.find_by_subject(db, request.subject)

        if not tutorial:
            # If subject not found, provide helpful error
            raise HTTPException(
                status_code=404,
                detail=f"Subject '{request.subject}' not found in database. Please check the available subjects.",
            )

        logging.info(f"Selected tutorial: {tutorial.subject} (ID: {tutorial.id})")

        # Step 2: Get all steps for this specific tutorial
        query = (
            select(TutorialStepModel)
            .where(TutorialStepModel.tutorial_id == tutorial.id)
            .order_by(TutorialStepModel.step_number)
        )
        result = await db.execute(query)
        tutorial_steps_data = result.scalars().all()

        if not tutorial_steps_data:
            logging.warning(f"No steps found for tutorial {tutorial.id}")
            raise HTTPException(
                status_code=404,
                detail=f"No steps found for tutorial '{request.subject}'",
            )

        logging.info(f"Found {len(tutorial_steps_data)} steps for tutorial")

        # Step 3: Convert to the expected response format
        tutorial_steps = []
        for step_data in tutorial_steps_data:
            tutorial_steps.append(
                TutorialStep(
                    step_en=step_data.instruction_en,
                    step_de=step_data.instruction_de,
                    step_img=step_data.image_url,  # URL or base64
                )
            )

        # Step 4: Return tutorial with all its steps
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
        logging.error(f"Failed to load tutorial from database: {str(e)}")
        raise HTTPException(
            status_code=500, detail=f"Failed to load tutorial from database: {str(e)}"
        )
