from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import time

from config import settings
from models import (
    HealthResponse,
    FullTutorialRequest,
    FullTutorialResponse,
    TutorialStep,
    TutorialMetadata,
)

# from services.drawing_service import DrawingService
# from services.image_service import ImageService
from services.local_db_service import LocalDatabaseService

# from utils import create_session_folder

# Initialize FastAPI app
app = FastAPI(
    title="Nova Draw AI API",
    description="Backend API for Nova Draw AI - Step-by-step drawing tutorials with AI",
    version="1.0.0",
)

# Configure CORS for Flutter app
origins = settings.cors_origins.split(",") if settings.cors_origins != "*" else ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Initialize services
local_db_service = LocalDatabaseService()


# Health check routes
@app.get("/", response_model=HealthResponse)
async def root():
    """Root endpoint"""
    return {"status": "success", "message": "Welcome to Nova Draw AI API"}


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "message": "API is running"}


# Generate complete tutorial
# AI-powered tutorial generation (commented out - using local database instead)
# @app.post("/api/generate-tutorial", response_model=FullTutorialResponse)
# async def generate_tutorial(request: FullTutorialRequest):
#     """
#     Generate a complete drawing tutorial with steps in English & German plus base64 images.
#     """
#     try:
#         # Generate drawing steps in both languages
#         steps, steps_german, _ = drawing_service.generate_steps(request.subject)

#         # Create session folder for image storage
#         session_folder, _ = create_session_folder(
#             request.subject, settings.storage_path
#         )

#         # Generate images for all steps
#         tutorial_steps = []
#         previous_image_path = None

#         for i, step_description in enumerate(steps, start=1):
#             # Generate image for this step
#             image_path, base64_image, _ = image_service.generate_step_image(
#                 step_description=step_description,
#                 subject=request.subject,
#                 step_number=i,
#                 session_folder=session_folder,
#                 previous_image_path=previous_image_path,
#             )

#             # Create tutorial step
#             tutorial_steps.append(
#                 TutorialStep(
#                     step_en=step_description,
#                     step_de=steps_german[i - 1],
#                     step_img=base64_image,
#                 )
#             )

#             # Update for next iteration
#             previous_image_path = image_path

#         return FullTutorialResponse(
#             success="true",
#             metadata=TutorialMetadata(
#                 subject=request.subject,
#                 total_steps=len(tutorial_steps),
#             ),
#             steps=tutorial_steps,
#         )

#     except Exception as e:
#         raise HTTPException(
#             status_code=500, detail=f"Failed to generate tutorial: {str(e)}"
#         )


# Generate tutorial from local database
@app.post("/api/generate-tutorial-local", response_model=FullTutorialResponse)
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


# Run the application
if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=True,  # Enable auto-reload during development
    )
