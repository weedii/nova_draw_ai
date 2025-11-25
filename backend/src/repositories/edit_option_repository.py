"""
EditOptionRepository for custom EditOption queries.

Provides specialized query methods beyond basic CRUD operations.
For basic CRUD, use the @crud_enabled decorator methods on the EditOption model directly.

Why this repository exists:
- Centralizes complex queries related to edit options
- Provides methods to filter by category, subject, or combinations via Tutorial relationship
- Keeps business logic separate from models
"""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List, Optional
from sqlalchemy.orm import joinedload

from src.models import EditOption, Tutorial


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
        Find all edit options for a specific category and subject (English or German).

        This is the primary query method used when a kid selects a subject
        and needs to see all available edit options for that subject.

        Args:
            db: Async database session
            category: Category name (e.g., 'Animals' or 'Tiere')
            subject: Subject name (e.g., 'Dog' or 'Hund')

        Returns:
            List of EditOption instances matching the category and subject

        Example:
            options = await EditOptionRepository.find_by_category_and_subject(
                db, "Animals", "Dog"
            )
        """
        query = (
            select(EditOption)
            .join(Tutorial)
            .where(
                (
                    (Tutorial.category_en == category)
                    | (Tutorial.category_de == category)
                )
                & ((Tutorial.subject_en == subject) | (Tutorial.subject_de == subject))
            )
            .options(joinedload(EditOption.tutorial))
        )
        result = await db.execute(query)
        return result.scalars().unique().all()

    @staticmethod
    async def find_by_category(db: AsyncSession, category: str) -> List[EditOption]:
        """
        Find all edit options in a specific category (English or German).

        Useful for displaying all available edit options when browsing a category.

        Args:
            db: Async database session
            category: Category name (e.g., 'Animals' or 'Tiere')

        Returns:
            List of EditOption instances in the category

        Example:
            options = await EditOptionRepository.find_by_category(db, "Animals")
        """
        query = (
            select(EditOption)
            .join(Tutorial)
            .where(
                (Tutorial.category_en == category) | (Tutorial.category_de == category)
            )
            .options(joinedload(EditOption.tutorial))
        )
        result = await db.execute(query)
        return result.scalars().unique().all()

    @staticmethod
    async def find_by_subject(db: AsyncSession, subject: str) -> List[EditOption]:
        """
        Find all edit options for a specific subject across all categories (English or German).

        Useful for finding all variations of a subject (e.g., all "Dog" options).

        Args:
            db: Async database session
            subject: Subject name (e.g., 'Dog' or 'Hund')

        Returns:
            List of EditOption instances with the given subject

        Example:
            options = await EditOptionRepository.find_by_subject(db, "Dog")
        """
        query = (
            select(EditOption)
            .join(Tutorial)
            .where((Tutorial.subject_en == subject) | (Tutorial.subject_de == subject))
            .options(joinedload(EditOption.tutorial))
        )
        result = await db.execute(query)
        return result.scalars().unique().all()

    @staticmethod
    async def get_all_categories(db: AsyncSession) -> List[str]:
        """
        Get all unique categories that have edit options (English names).

        Used for displaying available categories to the user.

        Args:
            db: Async database session

        Returns:
            List of unique category names (English)

        Example:
            categories = await EditOptionRepository.get_all_categories(db)
        """
        query = select(Tutorial.category_en).distinct().join(EditOption)
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def get_subjects_by_category(db: AsyncSession, category: str) -> List[str]:
        """
        Get all unique subjects in a specific category (English names).

        Used for displaying available subjects when a category is selected.

        Args:
            db: Async database session
            category: Category name (e.g., 'Animals' or 'Tiere')

        Returns:
            List of unique subject names in the category (English)

        Example:
            subjects = await EditOptionRepository.get_subjects_by_category(db, "Animals")
        """
        query = (
            select(Tutorial.subject_en)
            .distinct()
            .join(EditOption)
            .where(
                (Tutorial.category_en == category) | (Tutorial.category_de == category)
            )
        )
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def category_exists(db: AsyncSession, category: str) -> bool:
        """
        Check if a category has any edit options (English or German).

        Args:
            db: Async database session
            category: Category name to check (e.g., 'Animals' or 'Tiere')

        Returns:
            True if category exists, False otherwise

        Example:
            exists = await EditOptionRepository.category_exists(db, "Animals")
        """
        query = (
            select(EditOption)
            .join(Tutorial)
            .where(
                (Tutorial.category_en == category) | (Tutorial.category_de == category)
            )
            .limit(1)
        )
        result = await db.execute(query)
        return result.scalar_one_or_none() is not None

    @staticmethod
    async def subject_exists_in_category(
        db: AsyncSession, category: str, subject: str
    ) -> bool:
        """
        Check if a subject exists in a specific category (English or German).

        Args:
            db: Async database session
            category: Category name (e.g., 'Animals' or 'Tiere')
            subject: Subject name (e.g., 'Dog' or 'Hund')

        Returns:
            True if subject exists in category, False otherwise

        Example:
            exists = await EditOptionRepository.subject_exists_in_category(
                db, "Animals", "Dog"
            )
        """
        query = (
            select(EditOption)
            .join(Tutorial)
            .where(
                (
                    (Tutorial.category_en == category)
                    | (Tutorial.category_de == category)
                )
                & ((Tutorial.subject_en == subject) | (Tutorial.subject_de == subject))
            )
            .limit(1)
        )
        result = await db.execute(query)
        return result.scalar_one_or_none() is not None
