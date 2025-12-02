"""
Drawing endpoints for managing user drawings and gallery.

Handles HTTP requests/responses for drawing gallery operations.
Delegates business logic to DrawingGalleryService.
"""

import logging
from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID

from src.database import get_db
from src.models import User
from src.services import AuthService
from src.services.drawing_gallery_service import DrawingGalleryService
from src.schemas import DrawingResponse, DrawingListResponse

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/drawings", tags=["drawings"])


@router.get("/gallery", response_model=DrawingListResponse)
async def get_user_gallery(
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(AuthService.get_current_user),
):
    """
    Get user's drawing gallery with pagination.

    Returns all drawings created by the authenticated user, ordered by most recent first.

    **Authentication Required:** User must be logged in.

    Query Parameters:
    - page: Page number (default: 1)
    - limit: Items per page (default: 20, max: 100)

    Returns:
    - List of user's drawings with original and edited image URLs
    - Pagination info (page, limit, count)
    """

    try:
        logger.info(f"📸 Fetching gallery for user: {current_user.id}")

        # Initialize service
        drawing_gallery_service = DrawingGalleryService()

        # Delegate to service layer
        result = await drawing_gallery_service.get_user_gallery(
            db=db,
            user_id=current_user.id,
            page=page,
            limit=limit,
        )

        # Convert to response models
        drawing_responses = [
            DrawingResponse.from_orm(drawing) for drawing in result["drawings"]
        ]

        logger.info(
            f"✅ Retrieved {len(drawing_responses)} drawings for user {current_user.id}"
        )

        return DrawingListResponse(
            success=True,
            data=drawing_responses,
            count=result["total_count"],
            page=result["page"],
            limit=result["limit"],
        )

    except ValueError as e:
        logger.warning(f"⚠️ Validation error: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"❌ Failed to fetch gallery: {str(e)}")
        raise HTTPException(
            status_code=500, detail=f"Failed to fetch gallery: {str(e)}"
        )


@router.get("/{drawing_id}", response_model=DrawingResponse)
async def get_drawing(
    drawing_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(AuthService.get_current_user),
):
    """
    Get a specific drawing by ID.

    Only the owner of the drawing can retrieve it.

    **Authentication Required:** User must be logged in.

    Path Parameters:
    - drawing_id: UUID of the drawing

    Returns:
    - Drawing details with original and edited image URLs
    """

    try:
        logger.info(f"📸 Fetching drawing: {drawing_id}")

        # Initialize service
        drawing_gallery_service = DrawingGalleryService()

        # Delegate to service layer
        drawing = await drawing_gallery_service.get_drawing(
            db=db,
            drawing_id=drawing_id,
            user_id=current_user.id,
        )

        logger.info(f"✅ Retrieved drawing: {drawing_id}")

        return DrawingResponse.from_orm(drawing)

    except ValueError as e:
        logger.warning(f"⚠️ {str(e)}")
        if "permission" in str(e).lower():
            raise HTTPException(status_code=403, detail=str(e))
        else:
            raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"❌ Failed to fetch drawing: {str(e)}")
        raise HTTPException(
            status_code=500, detail=f"Failed to fetch drawing: {str(e)}"
        )


@router.delete("/{drawing_id}")
async def delete_drawing(
    drawing_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(AuthService.get_current_user),
):
    """
    Delete a drawing by ID.

    Only the owner of the drawing can delete it.
    Note: Images in Spaces are NOT automatically deleted (can be cleaned up later).

    **Authentication Required:** User must be logged in.

    Path Parameters:
    - drawing_id: UUID of the drawing

    Returns:
    - Success message
    """

    try:
        logger.info(f"🗑️  Deleting drawing: {drawing_id}")

        # Initialize service
        drawing_gallery_service = DrawingGalleryService()

        # Delegate to service layer
        result = await drawing_gallery_service.delete_drawing(
            db=db,
            drawing_id=drawing_id,
            user_id=current_user.id,
        )

        logger.info(f"✅ Drawing deleted: {drawing_id}")

        return result

    except ValueError as e:
        logger.warning(f"⚠️ {str(e)}")
        if "permission" in str(e).lower():
            raise HTTPException(status_code=403, detail=str(e))
        else:
            raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"❌ Failed to delete drawing: {str(e)}")
        raise HTTPException(
            status_code=500, detail=f"Failed to delete drawing: {str(e)}"
        )


@router.delete("/{drawing_id}/images")
async def delete_drawing_image(
    drawing_id: UUID,
    image_url: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(AuthService.get_current_user),
):
    """
    Delete a specific image from a drawing by URL.

    Only the owner of the drawing can delete images from it.
    Note: Images in Spaces are NOT automatically deleted (can be cleaned up later).

    **Authentication Required:** User must be logged in.

    Path Parameters:
    - drawing_id: UUID of the drawing

    Query Parameters:
    - image_url: URL of the image to delete

    Returns:
    - Success message with updated image URLs
    """

    try:
        logger.info(f"🗑️  Deleting image from drawing: {drawing_id}")

        # Initialize service
        drawing_gallery_service = DrawingGalleryService()

        # Delegate to service layer
        result = await drawing_gallery_service.delete_drawing_image(
            db=db,
            drawing_id=drawing_id,
            image_url=image_url,
            user_id=current_user.id,
        )

        logger.info(f"✅ Image deleted from drawing: {drawing_id}")

        return result

    except ValueError as e:
        logger.warning(f"⚠️ {str(e)}")
        if "permission" in str(e).lower():
            raise HTTPException(status_code=403, detail=str(e))
        else:
            raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"❌ Failed to delete image: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to delete image: {str(e)}")


@router.get("/stats/summary")
async def get_gallery_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(AuthService.get_current_user),
):
    """
    Get summary statistics about user's drawings.

    **Authentication Required:** User must be logged in.

    Returns:
    - Total number of drawings
    - Number of drawings with edited images
    - Number of drawings with tutorials
    """

    try:
        logger.info(f"📊 Fetching gallery stats for user: {current_user.id}")

        # Initialize service
        drawing_gallery_service = DrawingGalleryService()

        # Delegate to service layer
        result = await drawing_gallery_service.get_gallery_stats(
            db=db,
            user_id=current_user.id,
        )

        logger.info(f"✅ Retrieved stats for user {current_user.id}")

        return result

    except ValueError as e:
        logger.warning(f"⚠️ {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"❌ Failed to fetch stats: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch stats: {str(e)}")
