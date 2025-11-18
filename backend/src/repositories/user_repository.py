"""
UserRepository for custom User queries.

Provides specialized query methods beyond basic CRUD operations.
For basic CRUD, use the @crud_enabled decorator methods on the User model directly.
"""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional, List
from uuid import UUID

from models import User


class UserRepository:
    """
    Repository for User model queries.

    Provides custom query methods for specialized use cases.
    For basic CRUD operations, use User.create(), User.get_by_id(), etc.
    """

    @staticmethod
    async def find_by_email(db: AsyncSession, email: str) -> Optional[User]:
        """
        Find a user by email address.

        Args:
            db: Async database session
            email: User email address

        Returns:
            User instance or None if not found

        Example:
            user = await UserRepository.find_by_email(db, "user@example.com")
        """
        query = select(User).where(User.email == email)
        result = await db.execute(query)
        return result.scalar_one_or_none()

    @staticmethod
    async def find_by_email_or_id(
        db: AsyncSession, email: str, user_id: UUID
    ) -> Optional[User]:
        """
        Find a user by email or ID.

        Args:
            db: Async database session
            email: User email address
            user_id: User ID

        Returns:
            User instance or None if not found

        Example:
            user = await UserRepository.find_by_email_or_id(db, "user@example.com", user_id)
        """
        query = select(User).where((User.email == email) | (User.id == user_id))
        result = await db.execute(query)
        return result.scalar_one_or_none()

    @staticmethod
    async def get_all_users(db: AsyncSession) -> List[User]:
        """
        Get all users.

        Args:
            db: Async database session

        Returns:
            List of all User instances

        Example:
            users = await UserRepository.get_all_users(db)
        """
        query = select(User)
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def get_users_by_name(db: AsyncSession, name_pattern: str) -> List[User]:
        """
        Get users by name pattern (case-insensitive).

        Args:
            db: Async database session
            name_pattern: Name pattern to search for

        Returns:
            List of matching User instances

        Example:
            users = await UserRepository.get_users_by_name(db, "john")
        """
        query = select(User).where(User.name.ilike(f"%{name_pattern}%"))
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def email_exists(db: AsyncSession, email: str) -> bool:
        """
        Check if an email already exists.

        Args:
            db: Async database session
            email: Email to check

        Returns:
            True if email exists, False otherwise

        Example:
            exists = await UserRepository.email_exists(db, "user@example.com")
        """
        user = await UserRepository.find_by_email(db, email)
        return user is not None
