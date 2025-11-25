"""
TutorialRepository for custom Tutorial queries.

Provides specialized query methods beyond basic CRUD operations.
For basic CRUD, use the @crud_enabled decorator methods on the Tutorial model directly.
"""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import Optional, List

from src.models import Tutorial


class TutorialRepository:
    """
    Repository for Tutorial model queries.

    Provides custom query methods for specialized use cases.
    For basic CRUD operations, use Tutorial.create(), Tutorial.get_by_id(), etc.
    """

    @staticmethod
    async def find_by_subject(db: AsyncSession, subject: str) -> Optional[Tutorial]:
        """
        Find a random tutorial by subject name (English or German).

        Args:
            db: Async database session
            subject: Tutorial subject name (case-insensitive)

        Returns:
            Random Tutorial instance or None if none found

        Example:
            tutorial = await TutorialRepository.find_by_subject(db, "cat")
        """

        # Get a random tutorial with the given subject (case-insensitive, checks both EN and DE)
        query = (
            select(Tutorial)
            .where(
                (func.lower(Tutorial.subject_en) == func.lower(subject))
                | (func.lower(Tutorial.subject_de) == func.lower(subject))
            )
            .order_by(func.random())
            .limit(1)
        )

        result = await db.execute(query)
        return result.scalar_one_or_none()

    @staticmethod
    async def find_by_category(db: AsyncSession, category: str) -> List[Tutorial]:
        """
        Find all tutorials in a specific category (English or German).

        Args:
            db: Async database session
            category: Tutorial category

        Returns:
            List of Tutorial instances in the category

        Example:
            tutorials = await TutorialRepository.find_by_category(db, "animals")
        """

        query = select(Tutorial).where(
            (func.lower(Tutorial.category_en) == func.lower(category))
            | (func.lower(Tutorial.category_de) == func.lower(category))
        )
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def get_all_categories(db: AsyncSession) -> List[str]:
        """
        Get all unique tutorial categories (English names).

        Args:
            db: Async database session

        Returns:
            List of unique category names (English)

        Example:
            categories = await TutorialRepository.get_all_categories(db)
        """

        query = select(Tutorial.category_en).distinct()
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def find_by_subject_pattern(db: AsyncSession, pattern: str) -> List[Tutorial]:
        """
        Find tutorials by subject pattern (case-insensitive, checks both EN and DE).

        Args:
            db: Async database session
            pattern: Subject pattern to search for

        Returns:
            List of matching Tutorial instances

        Example:
            tutorials = await TutorialRepository.find_by_subject_pattern(db, "cat")
        """

        query = select(Tutorial).where(
            (Tutorial.subject_en.ilike(f"%{pattern}%"))
            | (Tutorial.subject_de.ilike(f"%{pattern}%"))
        )
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def get_tutorials_with_steps(db: AsyncSession) -> List[Tutorial]:
        """
        Get all tutorials that have steps defined.

        Args:
            db: Async database session

        Returns:
            List of Tutorial instances with steps

        Example:
            tutorials = await TutorialRepository.get_tutorials_with_steps(db)
        """

        query = select(Tutorial).where(Tutorial.total_steps > 0)
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def subject_exists(db: AsyncSession, subject: str) -> bool:
        """
        Check if a tutorial with a specific subject exists.

        Args:
            db: Async database session
            subject: Subject to check

        Returns:
            True if subject exists, False otherwise

        Example:
            exists = await TutorialRepository.subject_exists(db, "cat")
        """

        tutorial = await TutorialRepository.find_by_subject(db, subject)
        return tutorial is not None

    @staticmethod
    async def get_all_tutorials_grouped_by_category(
        db: AsyncSession,
    ) -> List[Tutorial]:
        """
        Query all tutorials from database, ordered and grouped by category.

        This method returns all tutorials ordered by category name, which allows
        the service layer to group them into nested category structures.

        Args:
            db: Async database session

        Returns:
            List of all Tutorial instances ordered by category

        Example:
            tutorials = await TutorialRepository.get_all_tutorials_grouped_by_category(db)
        """

        query = select(Tutorial).order_by(Tutorial.category_en, Tutorial.subject_en)
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def get_all_tutorials_for_category(
        db: AsyncSession, category: str
    ) -> List[Tutorial]:
        """
        Query all tutorials for a specific category with complete metadata.

        Uses case-insensitive matching for the category name (English or German).

        Args:
            db: Async database session
            category: Category name to filter by

        Returns:
            List of Tutorial instances in the specified category

        Example:
            tutorials = await TutorialRepository.get_all_tutorials_for_category(db, "Animals")
        """

        query = (
            select(Tutorial)
            .where(
                (func.lower(Tutorial.category_en) == func.lower(category))
                | (func.lower(Tutorial.category_de) == func.lower(category))
            )
            .order_by(Tutorial.subject_en)
        )
        result = await db.execute(query)
        return result.scalars().all()
