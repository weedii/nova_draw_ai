from fastapi import APIRouter
from models import HealthResponse

router = APIRouter()


@router.get("/", response_model=HealthResponse)
async def root():
    """Root endpoint"""
    return {"status": "success", "message": "Welcome to Nova Draw AI API"}


@router.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "message": "API is running"}
