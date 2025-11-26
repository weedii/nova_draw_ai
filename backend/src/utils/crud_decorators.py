"""
CRUD Decorators for SQLAlchemy models with async support.
Provides automatic CRUD operations without complex architecture overhead.

All methods are classmethods that work with async SQLAlchemy sessions.
"""

from typing import Type, Any, List, Dict, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select
from datetime import datetime, timezone


def crud_enabled(cls: Type[Any]) -> Type[Any]:
    """
    Decorator that adds async CRUD operations to SQLAlchemy models.

    Automatically adds the following async classmethods to your model:
    - create(db, **kwargs) -> Model
    - get_by_id(db, id) -> Model | None
    - get_all(db) -> List[Model]
    - get_paginated(db, page, limit) -> Dict
    - update(db, id, updates) -> Model | None
    - delete(db, id) -> bool
    - count(db) -> int
    - exists(db, id) -> bool

    Features:
    - Auto-updates updated_at field on updates
    - Built-in pagination support
    - Type-safe operations
    - Async-compatible for use with FastAPI
    - Hard delete (permanent removal from database)

    Usage:
        @crud_enabled
        @auditable
        class User(Base):
            __tablename__ = "users"
            # your fields here

        # Usage in endpoints:
        user = await User.create(db, email="test@test.com")
        user = await User.get_by_id(db, user_id)
        users = await User.get_paginated(db, page=1, limit=10)
    """

    # CREATE OPERATION
    @classmethod
    async def create(cls, db: AsyncSession, **kwargs) -> cls:
        """
        Create a new record in the database.

        Args:
            db: Async database session
            **kwargs: Field values for the new record

        Returns:
            Created model instance

        Example:
            user = await User.create(db, email="test@test.com", first_name="John")
        """
        obj = cls(**kwargs)
        db.add(obj)
        await db.commit()
        await db.refresh(obj)
        return obj

    # READ OPERATIONS
    @classmethod
    async def get_by_id(cls, db: AsyncSession, id: Any) -> Optional[cls]:
        """
        Get a record by its ID.

        Args:
            db: Async database session
            id: Primary key value

        Returns:
            Model instance or None if not found

        Example:
            user = await User.get_by_id(db, user_id)
        """
        query = select(cls).where(cls.id == id)
        result = await db.execute(query)
        return result.scalar_one_or_none()

    @classmethod
    async def get_all(cls, db: AsyncSession) -> List[cls]:
        """
        Get all records.

        Args:
            db: Async database session

        Returns:
            List of all model instances

        Example:
            users = await User.get_all(db)
        """
        query = select(cls)
        result = await db.execute(query)
        return result.scalars().all()

    @classmethod
    async def get_paginated(
        cls, db: AsyncSession, page: int = 1, limit: int = 10
    ) -> Dict[str, Any]:
        """
        Get paginated records with metadata.

        Args:
            db: Async database session
            page: Page number (1-based)
            limit: Number of records per page

        Returns:
            Dictionary with 'items', 'total', 'page', 'limit', 'pages'

        Example:
            result = await User.get_paginated(db, page=2, limit=20)
            users = result['items']
            total_pages = result['pages']
        """
        if page < 1:
            page = 1
        if limit < 1:
            limit = 10

        offset = (page - 1) * limit

        # Get total count
        count_query = select(func.count(cls.id))
        count_result = await db.execute(count_query)
        total = count_result.scalar()

        # Get paginated items
        items_query = select(cls)
        items_query = items_query.offset(offset).limit(limit)
        items_result = await db.execute(items_query)
        items = items_result.scalars().all()

        return {
            "items": items,
            "total": total,
            "page": page,
            "limit": limit,
            "pages": (total + limit - 1) // limit if total > 0 else 0,
        }

    # UPDATE OPERATION
    @classmethod
    async def update(
        cls, db: AsyncSession, id: Any, updates: Dict[str, Any]
    ) -> Optional[cls]:
        """
        Update a record by ID.

        Args:
            db: Async database session
            id: Primary key value
            updates: Dictionary of field updates

        Returns:
            Updated model instance or None if not found

        Example:
            user = await User.update(db, user_id, {"first_name": "Jane", "is_verified": True})
        """
        obj = await cls.get_by_id(db, id)
        if not obj:
            return None

        # Apply updates
        for field, value in updates.items():
            if hasattr(obj, field):
                setattr(obj, field, value)

        # Auto-update updated_at timestamp if field exists
        if hasattr(obj, "updated_at"):
            # Use timezone-aware UTC datetime, then strip timezone for naive column
            obj.updated_at = datetime.now(timezone.utc).replace(tzinfo=None)

        await db.commit()
        await db.refresh(obj)
        return obj

    # DELETE OPERATION
    @classmethod
    async def delete(cls, db: AsyncSession, id: Any) -> bool:
        """
        Delete a record by ID (hard delete - permanent removal).

        Args:
            db: Async database session
            id: Primary key value

        Returns:
            True if deleted successfully, False if not found

        Example:
            success = await User.delete(db, user_id)
        """
        obj = await cls.get_by_id(db, id)
        if not obj:
            return False

        # Hard delete: remove from database
        await db.delete(obj)
        await db.commit()

        return True

    # UTILITY OPERATIONS
    @classmethod
    async def count(cls, db: AsyncSession) -> int:
        """
        Count all records.

        Args:
            db: Async database session

        Returns:
            Total count of records

        Example:
            total_users = await User.count(db)
        """
        query = select(func.count(cls.id))
        result = await db.execute(query)
        return result.scalar()

    @classmethod
    async def exists(cls, db: AsyncSession, id: Any) -> bool:
        """
        Check if a record exists by ID.

        Args:
            db: Async database session
            id: Primary key value

        Returns:
            True if record exists, False otherwise

        Example:
            if await User.exists(db, user_id):
                print("User found!")
        """
        return await cls.get_by_id(db, id) is not None

    # Bind all methods to the class
    cls.create = create
    cls.get_by_id = get_by_id
    cls.get_all = get_all
    cls.get_paginated = get_paginated
    cls.update = update
    cls.delete = delete
    cls.count = count
    cls.exists = exists

    return cls
