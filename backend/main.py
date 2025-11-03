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
from services.drawing_service import DrawingService
from services.image_service import ImageService
from utils import create_session_folder

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
drawing_service = DrawingService()
image_service = ImageService()


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
@app.post("/api/generate-tutorial", response_model=FullTutorialResponse)
async def generate_tutorial(request: FullTutorialRequest):
    """
    Generate a complete drawing tutorial with steps in English & German plus base64 images.
    """
    try:
        # Generate drawing steps in both languages
        steps, steps_german, _ = drawing_service.generate_steps(request.subject)

        # Create session folder for image storage
        session_folder, _ = create_session_folder(
            request.subject, settings.storage_path
        )

        # Generate images for all steps
        tutorial_steps = []
        previous_image_path = None

        for i, step_description in enumerate(steps, start=1):
            # Generate image for this step
            image_path, base64_image, _ = image_service.generate_step_image(
                step_description=step_description,
                subject=request.subject,
                step_number=i,
                session_folder=session_folder,
                previous_image_path=previous_image_path,
            )

            # Create tutorial step
            tutorial_steps.append(
                TutorialStep(
                    step_en=step_description,
                    step_de=steps_german[i - 1],
                    step_img=base64_image,
                )
            )

            # Update for next iteration
            previous_image_path = image_path

        return FullTutorialResponse(
            success="true",
            metadata=TutorialMetadata(
                subject=request.subject,
                total_steps=len(tutorial_steps),
            ),
            steps=tutorial_steps,
        )

    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Failed to generate tutorial: {str(e)}"
        )


# Run the application
if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=True,  # Enable auto-reload during development
    )
