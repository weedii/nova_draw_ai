"""
EditOptionRepository for custom EditOption queries.

Provides specialized query methods beyond basic CRUD operations.
For basic CRUD, use the @crud_enabled decorator methods on the EditOption model directly.

Why this repository exists:
- Centralizes complex queries related to edit options
- Provides methods to filter by category, subject, or combinations
- Keeps business logic separate from models
"""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List, Optional

from src.models import EditOption


class EditOptionRepository:
    """
    Repository for EditOption model queries.

    Provides custom query methods for specialized use cases.
    For basic CRUD operations, use EditOption.create(), EditOption.get_by_id(), etc.
    """

    @staticmethod
    async def find_by_category_and_subject(
        db: AsyncSession, category: str, subject: str
    ) -> List[EditOption]:
        """
        Find all edit options for a specific category and subject.

        This is the primary query method used when a kid selects a subject
        and needs to see all available edit options for that subject.

        Args:
            db: Async database session
            category: Category name (e.g., 'Animals')
            subject: Subject name (e.g., 'dog')

        Returns:
            List of EditOption instances matching the category and subject

        Example:
            options = await EditOptionRepository.find_by_category_and_subject(
                db, "Animals", "dog"
            )
        """
        query = select(EditOption).where(
            (EditOption.category == category) & (EditOption.subject == subject)
        )
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def find_by_category(db: AsyncSession, category: str) -> List[EditOption]:
        """
        Find all edit options in a specific category.

        Useful for displaying all available edit options when browsing a category.

        Args:
            db: Async database session
            category: Category name

        Returns:
            List of EditOption instances in the category

        Example:
            options = await EditOptionRepository.find_by_category(db, "Animals")
        """
        query = select(EditOption).where(EditOption.category == category)
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def find_by_subject(db: AsyncSession, subject: str) -> List[EditOption]:
        """
        Find all edit options for a specific subject across all categories.

        Useful for finding all variations of a subject (e.g., all "dog" options).

        Args:
            db: Async database session
            subject: Subject name

        Returns:
            List of EditOption instances with the given subject

        Example:
            options = await EditOptionRepository.find_by_subject(db, "dog")
        """
        query = select(EditOption).where(EditOption.subject == subject)
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def get_all_categories(db: AsyncSession) -> List[str]:
        """
        Get all unique categories that have edit options.

        Used for displaying available categories to the user.

        Args:
            db: Async database session

        Returns:
            List of unique category names

        Example:
            categories = await EditOptionRepository.get_all_categories(db)
        """
        query = select(EditOption.category).distinct()
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def get_subjects_by_category(db: AsyncSession, category: str) -> List[str]:
        """
        Get all unique subjects in a specific category.

        Used for displaying available subjects when a category is selected.

        Args:
            db: Async database session
            category: Category name

        Returns:
            List of unique subject names in the category

        Example:
            subjects = await EditOptionRepository.get_subjects_by_category(db, "Animals")
        """
        query = (
            select(EditOption.subject).where(EditOption.category == category).distinct()
        )
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def category_exists(db: AsyncSession, category: str) -> bool:
        """
        Check if a category has any edit options.

        Args:
            db: Async database session
            category: Category name to check

        Returns:
            True if category exists, False otherwise

        Example:
            exists = await EditOptionRepository.category_exists(db, "Animals")
        """
        query = select(EditOption).where(EditOption.category == category).limit(1)
        result = await db.execute(query)
        return result.scalar_one_or_none() is not None

    @staticmethod
    async def subject_exists_in_category(
        db: AsyncSession, category: str, subject: str
    ) -> bool:
        """
        Check if a subject exists in a specific category.

        Args:
            db: Async database session
            category: Category name
            subject: Subject name

        Returns:
            True if subject exists in category, False otherwise

        Example:
            exists = await EditOptionRepository.subject_exists_in_category(
                db, "Animals", "dog"
            )
        """
        query = (
            select(EditOption)
            .where((EditOption.category == category) & (EditOption.subject == subject))
            .limit(1)
        )
        result = await db.execute(query)
        return result.scalar_one_or_none() is not None
