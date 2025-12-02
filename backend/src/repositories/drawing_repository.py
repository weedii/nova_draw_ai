"""
DrawingRepository for custom Drawing queries.

Provides specialized query methods beyond basic CRUD operations.
For basic CRUD, use the @crud_enabled decorator methods on the Drawing model directly.
"""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from sqlalchemy.orm import selectinload
from typing import Optional, List
from uuid import UUID

from src.models import Drawing


class DrawingRepository:
    """
    Repository for Drawing model queries.

    Provides custom query methods for specialized use cases.
    For basic CRUD operations, use Drawing.create(), Drawing.get_by_id(), etc.
    """

    @staticmethod
    async def find_by_user_id(db: AsyncSession, user_id: UUID) -> List[Drawing]:
        """
        Find all drawings created by a specific user.

        Args:
            db: Async database session
            user_id: User ID

        Returns:
            List of Drawing instances for the user

        Example:
            drawings = await DrawingRepository.find_by_user_id(db, user_id)
        """
        query = select(Drawing).where(Drawing.user_id == user_id)
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def find_by_tutorial_id(db: AsyncSession, tutorial_id: UUID) -> List[Drawing]:
        """
        Find all drawings created from a specific tutorial.

        Args:
            db: Async database session
            tutorial_id: Tutorial ID

        Returns:
            List of Drawing instances for the tutorial

        Example:
            drawings = await DrawingRepository.find_by_tutorial_id(db, tutorial_id)
        """
        query = select(Drawing).where(Drawing.tutorial_id == tutorial_id)
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def find_by_user_and_tutorial(
        db: AsyncSession, user_id: UUID, tutorial_id: UUID
    ) -> Optional[Drawing]:
        """
        Find a drawing created by a user from a specific tutorial.

        Args:
            db: Async database session
            user_id: User ID
            tutorial_id: Tutorial ID

        Returns:
            Drawing instance or None if not found

        Example:
            drawing = await DrawingRepository.find_by_user_and_tutorial(db, user_id, tutorial_id)
        """
        query = select(Drawing).where(
            Drawing.user_id == user_id,
            Drawing.tutorial_id == tutorial_id,
        )
        result = await db.execute(query)
        return result.scalar_one_or_none()

    @staticmethod
    async def find_by_id_with_tutorial(
        db: AsyncSession, drawing_id: UUID
    ) -> Optional[Drawing]:
        """
        Find a drawing by ID with eager-loaded tutorial relationship.

        Args:
            db: Async database session
            drawing_id: Drawing ID

        Returns:
            Drawing instance with tutorial loaded, or None if not found

        Example:
            drawing = await DrawingRepository.find_by_id_with_tutorial(db, drawing_id)
        """

        query = (
            select(Drawing)
            .where(Drawing.id == drawing_id)
            .options(selectinload(Drawing.tutorial))
        )
        result = await db.execute(query)
        return result.scalar_one_or_none()

    @staticmethod
    async def get_user_drawings_count(db: AsyncSession, user_id: UUID) -> int:
        """
        Get the count of drawings created by a user.

        Args:
            db: Async database session
            user_id: User ID

        Returns:
            Count of user's drawings

        Example:
            count = await DrawingRepository.get_user_drawings_count(db, user_id)
        """
        drawings = await DrawingRepository.find_by_user_id(db, user_id)
        return len(drawings)

    @staticmethod
    async def get_user_drawings_paginated(
        db: AsyncSession, user_id: UUID, page: int = 1, limit: int = 20
    ) -> List[Drawing]:
        """
        Get paginated drawings for a user, ordered by most recent first.

        Args:
            db: Async database session
            user_id: User ID
            page: Page number (1-indexed)
            limit: Items per page

        Returns:
            List of Drawing instances for the page

        Example:
            drawings = await DrawingRepository.get_user_drawings_paginated(db, user_id, page=1, limit=20)
        """

        offset = (page - 1) * limit
        query = (
            select(Drawing)
            .where(Drawing.user_id == user_id)
            .options(selectinload(Drawing.tutorial))
            .order_by(desc(Drawing.created_at))
            .offset(offset)
            .limit(limit)
        )
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def get_drawings_with_edits(db: AsyncSession, user_id: UUID) -> List[Drawing]:
        """
        Get all drawings by a user that have been edited.

        Args:
            db: Async database session
            user_id: User ID

        Returns:
            List of edited Drawing instances

        Example:
            edited_drawings = await DrawingRepository.get_drawings_with_edits(db, user_id)
        """
        query = select(Drawing).where(
            Drawing.user_id == user_id,
            Drawing.edited_images_urls.isnot(None),
        )
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def get_drawings_without_tutorial(
        db: AsyncSession, user_id: UUID
    ) -> List[Drawing]:
        """
        Get all drawings by a user that are not linked to any tutorial.

        Args:
            db: Async database session
            user_id: User ID

        Returns:
            List of Drawing instances without tutorial

        Example:
            drawings = await DrawingRepository.get_drawings_without_tutorial(db, user_id)
        """
        query = select(Drawing).where(
            Drawing.user_id == user_id,
            Drawing.tutorial_id.is_(None),
        )
        result = await db.execute(query)
        return result.scalars().all()
