from fastapi import APIRouter, HTTPException
from models import (
    FullTutorialRequest,
    FullTutorialResponse,
    TutorialStep,
    TutorialMetadata,
)
from services.local_db_service import LocalDatabaseService

router = APIRouter(prefix="/api", tags=["tutorials"])

# Initialize service
local_db_service = LocalDatabaseService()


@router.post("/generate-tutorial", response_model=FullTutorialResponse)
async def generate_tutorial_local(request: FullTutorialRequest):
    """
    Generate a drawing tutorial using the local database instead of AI.
    Returns the same format as the AI-generated tutorials.
    """
    try:
        # Get tutorial data from local database
        tutorial_data = local_db_service.get_tutorial_with_base64_images(
            request.subject
        )

        if not tutorial_data:
            # If subject not found, provide helpful error with available subjects
            available_subjects = local_db_service.list_all_subjects()
            raise HTTPException(
                status_code=404,
                detail=f"Subject '{request.subject}' not found in database. Available subjects: {', '.join(available_subjects[:10])}{'...' if len(available_subjects) > 10 else ''}",
            )

        # Convert to the expected response format
        tutorial_steps = []
        for step_data in tutorial_data["steps"]:
            tutorial_steps.append(
                TutorialStep(
                    step_en=step_data["step_en"],
                    step_de=step_data["step_de"],
                    step_img=step_data["step_img"],
                )
            )

        return FullTutorialResponse(
            success="true",
            metadata=TutorialMetadata(
                subject=tutorial_data["subject"],
                total_steps=tutorial_data["total_steps"],
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
