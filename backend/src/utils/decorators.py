"""
Model decorators for adding common functionality to SQLAlchemy models.
Provides timestamp tracking and audit trail capabilities.

These decorators reduce boilerplate code and ensure consistency across models.
"""

from sqlalchemy import Column, DateTime, event
from datetime import datetime, timezone
from typing import Type, Any


def timestamped(cls: Type[Any]) -> Type[Any]:
    """
    Decorator to add created_at and updated_at fields to a SQLAlchemy model.

    Automatically adds:
    - created_at: Set on creation, never changes
    - updated_at: Set on creation, updated on every change

    Usage:
        @timestamped
        class MyModel(Base):
            __tablename__ = "my_table"
            # your fields here

    Example:
        model = MyModel.create(db, field="value")
        print(model.created_at)  # 2024-01-15 10:30:00
        print(model.updated_at)  # 2024-01-15 10:30:00
    """

    # Add created_at and updated_at columns
    # Use datetime.utcnow() for timezone-naive timestamps (compatible with PostgreSQL TIMESTAMP WITHOUT TIME ZONE)
    cls.created_at = Column(
        DateTime, default=datetime.utcnow, nullable=False
    )
    cls.updated_at = Column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )

    return cls


def auditable(cls: Type[Any]) -> Type[Any]:
    """
    Decorator to add audit trail with created_at and updated_at fields.

    Recommended for all business-critical models.

    Usage:
        @auditable
        class MyModel(Base):
            __tablename__ = "my_table"
            # your fields here

    Example:
        model = MyModel.create(db, field="value")
        print(model.created_at)  # Timestamp
        print(model.updated_at)  # Timestamp
    """

    # Apply timestamped decorator
    cls = timestamped(cls)

    return cls


def auto_updated(cls: Type[Any]) -> Type[Any]:
    """
    Enhanced decorator that automatically updates the updated_at field
    whenever any field in the model is changed.

    Useful for frequently updated configuration models.

    Usage:
        @auto_updated
        class MyModel(Base):
            __tablename__ = "my_table"
            # your fields here
    """

    # First apply timestamped decorator
    cls = timestamped(cls)

    # Add event listener for automatic updated_at updates
    @event.listens_for(cls, "before_update")
    def receive_before_update(mapper, connection, target):
        target.updated_at = datetime.utcnow()

    return cls


def creation_tracked(cls: Type[Any]) -> Type[Any]:
    """
    Decorator to add only created_at field for read-only/immutable records.

    Useful for log entries, events, or other immutable records where
    you only need to track creation time.

    Usage:
        @creation_tracked
        class MyModel(Base):
            __tablename__ = "my_table"
            # your fields here
    """

    # Add only created_at column
    # Use datetime.utcnow() for timezone-naive timestamps (compatible with PostgreSQL TIMESTAMP WITHOUT TIME ZONE)
    cls.created_at = Column(
        DateTime, default=datetime.utcnow, nullable=False
    )

    return cls
