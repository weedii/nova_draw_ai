from fastapi import FastAPI, HTTPException, UploadFile, File, Form
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
    ImageProcessRequest,
    ImageProcessResponse,
    StoryRequest,
    StoryResponse,
)

# from services.drawing_service import DrawingService
# from services.image_service import ImageService
from services.local_db_service import LocalDatabaseService
from services.image_processing_service import ImageProcessingService
from services.story_service import StoryService

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

# Initialize image processing service (requires both Google and OpenAI API keys)
image_processing_service = None
if settings.google_api_key and settings.openai_api_key:
    try:
        image_processing_service = ImageProcessingService()
    except Exception as e:
        print(f"Warning: Could not initialize image processing service: {e}")
elif not settings.google_api_key:
    print("Warning: Google API key not configured - image processing unavailable")
elif not settings.openai_api_key:
    print("Warning: OpenAI API key not configured - image processing unavailable")

# Initialize story service (only if OpenAI API key is available)
story_service = None
if settings.openai_api_key:
    try:
        story_service = StoryService()
    except Exception as e:
        print(f"Warning: Could not initialize story service: {e}")


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
@app.post("/api/generate-tutorial", response_model=FullTutorialResponse)
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


# Edit uploaded image with AI
@app.post("/api/edit-image", response_model=ImageProcessResponse)
async def edit_image(
    file: UploadFile = File(..., description="Image file to process"),
    prompt: str = Form(
        ..., description="Processing instruction (e.g., 'make it alive')"
    ),
):
    """
    Edit an uploaded image with AI using a text prompt.
    Supports prompts like 'make it alive', 'make it colorful', etc.
    """
    try:
        # Check if image processing service is available
        if not image_processing_service:
            raise HTTPException(
                status_code=503,
                detail="Image processing service not available. Please configure both Google and OpenAI API keys.",
            )

        # Validate file type
        if not file.content_type or not file.content_type.startswith("image/"):
            raise HTTPException(
                status_code=400, detail="File must be an image (JPEG, PNG, etc.)"
            )

        # Read image data
        image_data = await file.read()

        # Validate image
        if not image_processing_service.validate_image(image_data):
            raise HTTPException(
                status_code=400,
                detail="Invalid image or image too large (max 2048x2048)",
            )

        # Get image info for logging
        image_info = image_processing_service.get_image_info(image_data)
        print(f"Processing image: {image_info}")

        # Process the image
        result_base64, processing_time = image_processing_service.process_image(
            image_data, prompt
        )

        return ImageProcessResponse(
            success="true",
            prompt=prompt,
            result_image=result_base64,
            processing_time=processing_time,
        )

    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to edit image: {str(e)}")


# Generate story from image
@app.post("/api/create-story", response_model=StoryResponse)
async def create_story(request: StoryRequest):
    """
    Generate a children's story (ages 4-7) from an uploaded image.
    User just needs to provide the image - we handle the rest!
    """
    try:
        # Check if story service is available
        if not story_service:
            raise HTTPException(
                status_code=503,
                detail="Story generation service not available. Please configure OpenAI API key.",
            )

        # Validate the base64 image
        if not story_service.validate_image_base64(request.image):
            raise HTTPException(
                status_code=400,
                detail="Invalid image data. Please provide a valid base64 encoded image.",
            )

        # Generate the story
        title, story, generation_time = story_service.generate_story(request.image)

        return StoryResponse(
            success="true",
            story=story,
            title=title,
            generation_time=generation_time,
        )

    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Failed to generate story: {str(e)}"
        )


# Run the application
if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=True,  # Enable auto-reload during development
    )
