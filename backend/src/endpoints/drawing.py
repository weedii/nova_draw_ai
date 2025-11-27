"""
Drawing endpoints for managing user drawings and gallery.
Handles retrieving, listing, and deleting user drawings.
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from sqlalchemy.orm import selectinload
from uuid import UUID

from src.database import get_db
from src.models import Drawing, User
from src.services import AuthService
from src.schemas import DrawingResponse, DrawingListResponse
from src.core.logger import logger

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

        # Calculate offset
        offset = (page - 1) * limit

        # Query total count
        count_query = select(Drawing).where(Drawing.user_id == current_user.id)
        count_result = await db.execute(count_query)
        total_count = len(count_result.scalars().all())

        # Query paginated drawings (most recent first) with tutorial eager loading
        query = (
            select(Drawing)
            .where(Drawing.user_id == current_user.id)
            .options(selectinload(Drawing.tutorial))
            .order_by(desc(Drawing.created_at))
            .offset(offset)
            .limit(limit)
        )

        result = await db.execute(query)
        drawings = result.scalars().all()

        logger.info(f"✅ Retrieved {len(drawings)} drawings for user {current_user.id}")

        # Convert to response models
        drawing_responses = [DrawingResponse.from_orm(drawing) for drawing in drawings]

        return DrawingListResponse(
            success=True,
            data=drawing_responses,
            count=total_count,
            page=page,
            limit=limit,
        )

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

        # Query drawing with tutorial eager loading
        query = (
            select(Drawing)
            .where(Drawing.id == drawing_id)
            .options(selectinload(Drawing.tutorial))
        )
        result = await db.execute(query)
        drawing = result.scalar_one_or_none()

        if not drawing:
            logger.warning(f"⚠️ Drawing not found: {drawing_id}")
            raise HTTPException(status_code=404, detail="Drawing not found")

        # Check ownership
        if drawing.user_id != current_user.id:
            logger.warning(
                f"⚠️ Unauthorized access attempt to drawing {drawing_id} by user {current_user.id}"
            )
            raise HTTPException(
                status_code=403,
                detail="You don't have permission to access this drawing",
            )

        logger.info(f"✅ Retrieved drawing: {drawing_id}")

        return DrawingResponse.from_orm(drawing)

    except HTTPException:
        raise
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

        # Query drawing
        query = select(Drawing).where(Drawing.id == drawing_id)
        result = await db.execute(query)
        drawing = result.scalar_one_or_none()

        if not drawing:
            logger.warning(f"⚠️ Drawing not found: {drawing_id}")
            raise HTTPException(status_code=404, detail="Drawing not found")

        # Check ownership
        if drawing.user_id != current_user.id:
            logger.warning(
                f"⚠️ Unauthorized deletion attempt for drawing {drawing_id} by user {current_user.id}"
            )
            raise HTTPException(
                status_code=403,
                detail="You don't have permission to delete this drawing",
            )

        # Delete from database
        await db.delete(drawing)
        await db.commit()

        logger.info(f"✅ Drawing deleted: {drawing_id}")

        return {
            "success": True,
            "message": "Drawing deleted successfully",
            "drawing_id": str(drawing_id),
        }

    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        logger.error(f"❌ Failed to delete drawing: {str(e)}")
        raise HTTPException(
            status_code=500, detail=f"Failed to delete drawing: {str(e)}"
        )


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

        # Query all drawings for user
        query = select(Drawing).where(Drawing.user_id == current_user.id)
        result = await db.execute(query)
        drawings = result.scalars().all()

        total_drawings = len(drawings)
        edited_count = sum(
            1
            for d in drawings
            if d.edited_images_urls and len(d.edited_images_urls) > 0
        )
        tutorial_count = sum(1 for d in drawings if d.tutorial_id is not None)

        logger.info(f"✅ Retrieved stats for user {current_user.id}")

        return {
            "success": True,
            "total_drawings": total_drawings,
            "edited_drawings": edited_count,
            "tutorial_drawings": tutorial_count,
        }

    except Exception as e:
        logger.error(f"❌ Failed to fetch stats: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch stats: {str(e)}")
