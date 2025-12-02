"""
Drawing Gallery Service for managing user drawings and gallery operations.

Handles business logic for retrieving, listing, and deleting user drawings.
Coordinates between repositories and database operations.
Manages deletion from both database and DigitalOcean Spaces storage.
"""

import logging
from typing import Dict, Any, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import attributes
from uuid import UUID

from src.models import Drawing
from src.repositories import DrawingRepository
from src.services.storage_service import StorageService

logger = logging.getLogger(__name__)


class DrawingGalleryService:
    """Service for drawing gallery operations"""

    def __init__(self):
        """Initialize service with storage client"""
        logger.info("Initializing DrawingGalleryService...")
        try:
            self.storage_service = StorageService()
        except Exception as e:
            logger.warning(f"⚠️ Failed to initialize StorageService: {str(e)}")
            self.storage_service = None
        logger.info("DrawingGalleryService initialized successfully")

    def _delete_image_from_spaces(self, image_url: str) -> bool:
        """
        Delete an image from DigitalOcean Spaces.

        Args:
            image_url: Public URL of the image

        Returns:
            True if deletion successful or storage service unavailable, False if error
        """
        if not self.storage_service:
            logger.warning("⚠️ StorageService not available, skipping Spaces deletion")
            return True

        try:
            logger.info(f"🗑️  Deleting image from Spaces: {image_url}")
            success = self.storage_service.delete_image(image_url)
            if success:
                logger.info(f"✅ Image deleted from Spaces: {image_url}")
            else:
                logger.warning(f"⚠️ Failed to delete image from Spaces: {image_url}")
            return success
        except Exception as e:
            logger.error(f"❌ Error deleting image from Spaces: {str(e)}")
            return False

    async def get_user_gallery(
        self,
        db: AsyncSession,
        user_id: UUID,
        page: int = 1,
        limit: int = 20,
    ) -> Dict[str, Any]:
        """
        Get user's drawing gallery with pagination.

        Args:
            db: Async database session
            user_id: UUID of the user
            page: Page number (1-indexed)
            limit: Items per page

        Returns:
            Dictionary with paginated drawings and metadata

        Raises:
            ValueError: If validation fails
        """
        try:
            logger.info(
                f"Fetching gallery for user: {user_id}, page: {page}, limit: {limit}"
            )

            # Validate pagination parameters
            if page < 1:
                raise ValueError("Page must be at least 1")
            if limit < 1 or limit > 100:
                raise ValueError("Limit must be between 1 and 100")

            # Get total count
            total_count = await DrawingRepository.get_user_drawings_count(db, user_id)

            # Get paginated drawings
            drawings = await DrawingRepository.get_user_drawings_paginated(
                db, user_id, page, limit
            )

            logger.info(f"Retrieved {len(drawings)} drawings for user {user_id}")

            return {
                "drawings": drawings,
                "total_count": total_count,
                "page": page,
                "limit": limit,
            }

        except ValueError:
            raise
        except Exception as e:
            logger.error(f"Failed to fetch gallery: {str(e)}")
            raise ValueError(f"Failed to fetch gallery: {str(e)}")

    async def get_drawing(
        self,
        db: AsyncSession,
        drawing_id: UUID,
        user_id: UUID,
    ) -> Drawing:
        """
        Get a specific drawing by ID.

        Args:
            db: Async database session
            drawing_id: UUID of the drawing
            user_id: UUID of the user (for ownership check)

        Returns:
            Drawing instance

        Raises:
            ValueError: If drawing not found or user doesn't own it
        """
        try:
            logger.info(f"Fetching drawing: {drawing_id}")

            # Get drawing with repository
            drawing = await DrawingRepository.find_by_id_with_tutorial(db, drawing_id)

            if not drawing:
                logger.warning(f"Drawing not found: {drawing_id}")
                raise ValueError("Drawing not found")

            # Check ownership
            if drawing.user_id != user_id:
                logger.warning(
                    f"Unauthorized access attempt to drawing {drawing_id} by user {user_id}"
                )
                raise ValueError("You don't have permission to access this drawing")

            logger.info(f"Retrieved drawing: {drawing_id}")
            return drawing

        except ValueError:
            raise
        except Exception as e:
            logger.error(f"Failed to fetch drawing: {str(e)}")
            raise ValueError(f"Failed to fetch drawing: {str(e)}")

    async def delete_drawing(
        self,
        db: AsyncSession,
        drawing_id: UUID,
        user_id: UUID,
    ) -> Dict[str, Any]:
        """
        Delete a drawing by ID.

        Deletes images from both database and DigitalOcean Spaces.

        Args:
            db: Async database session
            drawing_id: UUID of the drawing
            user_id: UUID of the user (for ownership check)

        Returns:
            Dictionary with success message and drawing ID

        Raises:
            ValueError: If drawing not found or user doesn't own it
        """
        try:
            logger.info(f"Deleting drawing: {drawing_id}")

            # Get drawing
            drawing = await DrawingRepository.find_by_id_with_tutorial(db, drawing_id)

            if not drawing:
                logger.warning(f"Drawing not found: {drawing_id}")
                raise ValueError("Drawing not found")

            # Check ownership
            if drawing.user_id != user_id:
                logger.warning(
                    f"Unauthorized deletion attempt for drawing {drawing_id} by user {user_id}"
                )
                raise ValueError("You don't have permission to delete this drawing")

            # Debug: Log drawing data
            logger.info(
                f"📋 Drawing data - uploaded_image_url: {drawing.uploaded_image_url}"
            )
            logger.info(
                f"📋 Drawing data - edited_images_urls: {drawing.edited_images_urls}"
            )
            logger.info(
                f"📋 Drawing data - edited_images_urls type: {type(drawing.edited_images_urls)}"
            )

            # Delete ALL images from Spaces before deleting from DB
            logger.info(f"🗑️  Deleting all images from Spaces for drawing {drawing_id}")

            # Delete original image
            if drawing.uploaded_image_url:
                logger.info(
                    f"🗑️  Deleting original image from Spaces: {drawing.uploaded_image_url}"
                )
                self._delete_image_from_spaces(drawing.uploaded_image_url)
            else:
                logger.warning(
                    f"⚠️ No original image URL found for drawing {drawing_id}"
                )

            # Delete all edited images
            if drawing.edited_images_urls and len(drawing.edited_images_urls) > 0:
                logger.info(
                    f"🗑️  Deleting {len(drawing.edited_images_urls)} edited images from Spaces"
                )
                for idx, image_url in enumerate(drawing.edited_images_urls, 1):
                    logger.info(
                        f"🗑️  Deleting edited image {idx}/{len(drawing.edited_images_urls)}: {image_url}"
                    )
                    self._delete_image_from_spaces(image_url)
            else:
                logger.info(f"ℹ️  No edited images to delete for drawing {drawing_id}")

            # Delete from database using model method
            await Drawing.delete(db, drawing_id)

            logger.info(f"Drawing deleted: {drawing_id}")

            return {
                "success": True,
                "message": "Drawing deleted successfully",
                "drawing_id": str(drawing_id),
            }

        except ValueError:
            raise
        except Exception as e:
            logger.error(f"Failed to delete drawing: {str(e)}")
            raise ValueError(f"Failed to delete drawing: {str(e)}")

    async def delete_drawing_image(
        self,
        db: AsyncSession,
        drawing_id: UUID,
        image_url: str,
        user_id: UUID,
    ) -> Dict[str, Any]:
        """
        Delete a specific image from a drawing by URL.

        Deletes image from both database and DigitalOcean Spaces.

        Args:
            db: Async database session
            drawing_id: UUID of the drawing
            image_url: URL of the image to delete
            user_id: UUID of the user (for ownership check)

        Returns:
            Dictionary with success message and updated drawing info

        Raises:
            ValueError: If validation fails or operation not allowed
        """

        try:
            logger.info(f"Deleting image from drawing: {drawing_id}")

            # Get drawing
            drawing = await DrawingRepository.find_by_id_with_tutorial(db, drawing_id)

            if not drawing:
                logger.warning(f"Drawing not found: {drawing_id}")
                raise ValueError("Drawing not found")

            # Check ownership
            if drawing.user_id != user_id:
                logger.warning(
                    f"Unauthorized deletion attempt for drawing {drawing_id} by user {user_id}"
                )
                raise ValueError(
                    "You don't have permission to delete images from this drawing"
                )

            # Check if image exists in drawing
            is_original = drawing.uploaded_image_url == image_url
            is_edited = image_url in (drawing.edited_images_urls or [])

            if not is_original and not is_edited:
                logger.warning(f"Image URL not found in drawing {drawing_id}")
                raise ValueError("Image not found in drawing")

            # Count total images
            all_images = [drawing.uploaded_image_url] + (
                drawing.edited_images_urls or []
            )

            # Delete image from Spaces first
            logger.info(f"🗑️  Deleting image from Spaces: {image_url}")
            self._delete_image_from_spaces(image_url)

            # If deleting the original/uploaded image, delete the entire drawing row
            # because the original/uploaded image cannot be null
            if is_original:
                # Delete all edited images from Spaces before deleting the drawing
                if drawing.edited_images_urls and len(drawing.edited_images_urls) > 0:
                    logger.info(
                        f"🗑️  Deleting {len(drawing.edited_images_urls)} edited images from Spaces before deleting drawing"
                    )
                    for idx, edited_url in enumerate(drawing.edited_images_urls, 1):
                        logger.info(
                            f"🗑️  Deleting edited image {idx}/{len(drawing.edited_images_urls)}: {edited_url}"
                        )
                        self._delete_image_from_spaces(edited_url)

                await Drawing.delete(db, drawing_id)
                logger.info(
                    f"Drawing deleted because original image was deleted: {drawing_id}"
                )
                return {
                    "success": True,
                    "message": "Drawing deleted successfully (original image cannot be deleted)",
                    "drawing_id": str(drawing_id),
                }

            # If only one image exists and it's an edited image, delete the entire drawing row
            if len(all_images) == 1 and is_edited:
                # Delete the original image from Spaces if it exists
                if drawing.uploaded_image_url:
                    logger.info(
                        f"🗑️  Deleting original image from Spaces before deleting drawing: {drawing.uploaded_image_url}"
                    )
                    self._delete_image_from_spaces(drawing.uploaded_image_url)

                await Drawing.delete(db, drawing_id)
                logger.info(
                    f"Drawing deleted because it had only one image: {drawing_id}"
                )
                return {
                    "success": True,
                    "message": "Drawing deleted successfully (only image was deleted)",
                    "drawing_id": str(drawing_id),
                }

            # Delete the edited image from DB
            if drawing.edited_images_urls:
                drawing.edited_images_urls.remove(image_url)
                # Flag the array as modified for PostgreSQL to detect the change
                attributes.flag_modified(drawing, "edited_images_urls")
                await db.commit()
                logger.info(f"Deleted edited image from drawing {drawing_id}")

            logger.info(f"Image deleted from drawing: {drawing_id}")

            return {
                "success": True,
                "message": "Image deleted successfully",
                "drawing_id": str(drawing_id),
                "uploaded_image_url": drawing.uploaded_image_url,
                "edited_images_urls": drawing.edited_images_urls or [],
            }

        except ValueError:
            raise
        except Exception as e:
            logger.error(f"Failed to delete image: {str(e)}")
            raise ValueError(f"Failed to delete image: {str(e)}")

    async def get_gallery_stats(
        self,
        db: AsyncSession,
        user_id: UUID,
    ) -> Dict[str, Any]:
        """
        Get summary statistics about user's drawings.

        Args:
            db: Async database session
            user_id: UUID of the user

        Returns:
            Dictionary with gallery statistics

        Raises:
            ValueError: If operation fails
        """
        try:
            logger.info(f"Fetching gallery stats for user: {user_id}")

            # Get all drawings for user
            drawings = await DrawingRepository.find_by_user_id(db, user_id)

            total_drawings = len(drawings)
            edited_count = sum(
                1
                for d in drawings
                if d.edited_images_urls and len(d.edited_images_urls) > 0
            )
            tutorial_count = sum(1 for d in drawings if d.tutorial_id is not None)

            logger.info(f"Retrieved stats for user {user_id}")

            return {
                "success": True,
                "total_drawings": total_drawings,
                "edited_drawings": edited_count,
                "tutorial_drawings": tutorial_count,
            }

        except Exception as e:
            logger.error(f"Failed to fetch stats: {str(e)}")
            raise ValueError(f"Failed to fetch stats: {str(e)}")
