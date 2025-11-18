"""
StoryRepository for custom Story queries.

Provides specialized query methods beyond basic CRUD operations.
For basic CRUD, use the @crud_enabled decorator methods on the Story model directly.
"""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional, List
from uuid import UUID

from src.models import Story


class StoryRepository:
    """
    Repository for Story model queries.

    Provides custom query methods for specialized use cases.
    For basic CRUD operations, use Story.create(), Story.get_by_id(), etc.
    """

    @staticmethod
    async def find_by_user_id(db: AsyncSession, user_id: UUID) -> List[Story]:
        """
        Find all stories created for a specific user.

        Args:
            db: Async database session
            user_id: User ID

        Returns:
            List of Story instances for the user

        Example:
            stories = await StoryRepository.find_by_user_id(db, user_id)
        """
        query = select(Story).where(Story.user_id == user_id)
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def find_by_drawing_id(db: AsyncSession, drawing_id: UUID) -> List[Story]:
        """
        Find all stories created from a specific drawing.

        Args:
            db: Async database session
            drawing_id: Drawing ID

        Returns:
            List of Story instances for the drawing

        Example:
            stories = await StoryRepository.find_by_drawing_id(db, drawing_id)
        """
        query = select(Story).where(Story.drawing_id == drawing_id)
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def get_user_favorite_stories(db: AsyncSession, user_id: UUID) -> List[Story]:
        """
        Get all favorite stories for a user.

        Args:
            db: Async database session
            user_id: User ID

        Returns:
            List of favorite Story instances

        Example:
            favorites = await StoryRepository.get_user_favorite_stories(db, user_id)
        """
        query = select(Story).where(
            Story.user_id == user_id,
            Story.is_favorite.is_(True),
        )
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def get_user_stories_count(db: AsyncSession, user_id: UUID) -> int:
        """
        Get the count of stories created for a user.

        Args:
            db: Async database session
            user_id: User ID

        Returns:
            Count of user's stories

        Example:
            count = await StoryRepository.get_user_stories_count(db, user_id)
        """
        stories = await StoryRepository.find_by_user_id(db, user_id)
        return len(stories)

    @staticmethod
    async def get_user_favorite_stories_count(db: AsyncSession, user_id: UUID) -> int:
        """
        Get the count of favorite stories for a user.

        Args:
            db: Async database session
            user_id: User ID

        Returns:
            Count of user's favorite stories

        Example:
            count = await StoryRepository.get_user_favorite_stories_count(db, user_id)
        """
        stories = await StoryRepository.get_user_favorite_stories(db, user_id)
        return len(stories)

    @staticmethod
    async def find_by_title(
        db: AsyncSession, user_id: UUID, title: str
    ) -> Optional[Story]:
        """
        Find a story by user and title.

        Args:
            db: Async database session
            user_id: User ID
            title: Story title

        Returns:
            Story instance or None if not found

        Example:
            story = await StoryRepository.find_by_title(db, user_id, "My Adventure")
        """
        query = select(Story).where(Story.user_id == user_id, Story.title == title)
        result = await db.execute(query)
        return result.scalar_one_or_none()

    @staticmethod
    async def find_by_title_pattern(
        db: AsyncSession, user_id: UUID, pattern: str
    ) -> List[Story]:
        """
        Find stories by title pattern (case-insensitive).

        Args:
            db: Async database session
            user_id: User ID
            pattern: Title pattern to search for

        Returns:
            List of matching Story instances

        Example:
            stories = await StoryRepository.find_by_title_pattern(db, user_id, "adventure")
        """
        query = select(Story).where(
            Story.user_id == user_id,
            Story.title.ilike(f"%{pattern}%"),
        )
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def toggle_favorite(db: AsyncSession, story_id: UUID) -> Optional[Story]:
        """
        Toggle the favorite status of a story.

        Args:
            db: Async database session
            story_id: Story ID

        Returns:
            Updated Story instance or None if not found

        Example:
            story = await StoryRepository.toggle_favorite(db, story_id)
        """
        story = await Story.get_by_id(db, story_id)
        if not story:
            return None

        updated = await Story.update(
            db, story_id, {"is_favorite": not story.is_favorite}
        )
        return updated
