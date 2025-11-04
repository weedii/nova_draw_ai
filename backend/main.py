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
        print(f"\n🎨 Starting tutorial generation for: {request.subject}")
        print("=" * 60)
        
        # Generate drawing steps in both languages
        print("📝 Generating drawing steps...")
        steps, steps_german, step_duration = drawing_service.generate_steps(request.subject)
        print(f"✅ Generated {len(steps)} steps in {step_duration:.2f}s")

        # Create session folder for image storage
        print(f"\n📁 Creating session folder...")
        session_folder, session_id = create_session_folder(
            request.subject, settings.storage_path
        )
        print(f"✅ Session folder created: {session_folder}")
        print(f"   Session ID: {session_id}")

        # Generate images for all steps
        print(f"\n🖼️ Generating images for {len(steps)} steps...")
        print("=" * 60)
        tutorial_steps = []
        previous_image_path = None

        for i, step_description in enumerate(steps, start=1):
            print(f"\n📋 Processing Step {i}/{len(steps)}")
            print(f"   English: {step_description}")
            print(f"   German: {steps_german[i-1]}")
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

        print(f"\n🎉 Tutorial generation completed!")
        print(f"   Total steps: {len(tutorial_steps)}")
        print(f"   Session ID: {session_id}")
        print("=" * 60)

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
