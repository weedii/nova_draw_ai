from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from src.core.config import settings
from src.endpoints import health, tutorial, image, story

# Initialize FastAPI app
app = FastAPI(
    title="Nova Draw AI API",
    description="Backend API for Nova Draw AI - Step-by-step drawing tutorials with AI",
    version="1.0.0",
)

# Configure CORS for Flutter app
origins = settings.CORS_ORIGINS.split(",") if settings.CORS_ORIGINS != "*" else ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health.router)
app.include_router(tutorial.router)
app.include_router(image.router)
app.include_router(story.router)


# Run the application
if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=True,  # Enable auto-reload during development
    )
