"""
User model for Nova Draw AI application.
Represents registered users with authentication and profile information.
"""

from sqlalchemy import Column, String, Date, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid

from src.database.db import Base
from src.utils import auditable, crud_enabled


@crud_enabled
@auditable
class User(Base):
    """
    User model representing registered users in the Nova Draw AI application.

    Includes authentication fields, profile information, and relationships
    to user-generated content (drawings and stories).

    Decorators:
    - @auditable: Adds created_at, updated_at for audit trail
    - @crud_enabled: Adds CRUD operations (create, get_by_id, get_all, get_paginated, update, delete, count, exists)

    Note: Password is hashed with bcrypt (not Fernet encryption).
    Bcrypt is the industry standard for password hashing and provides better security.
    """

    __tablename__ = "users"

    # Primary key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)

    # Profile information
    email = Column(String(255), unique=True, nullable=False, index=True)
    password = Column(String(255), nullable=False)
    name = Column(String(50), nullable=True)
    birthdate = Column(Date, nullable=True)

    # Password Reset
    reset_code = Column(String(6), nullable=True)
    reset_code_expires_at = Column(DateTime, nullable=True)

    # Relationships
    drawings = relationship(
        "Drawing", back_populates="user", cascade="all, delete-orphan"
    )
    stories = relationship("Story", back_populates="user", cascade="all, delete-orphan")

    # Note: created_at, updated_at are automatically added by @auditable
    #
    # CRUD operations added by @crud_enabled decorator:
    # - User.create(db, **kwargs) -> User
    # - User.get_by_id(db, id) -> User | None
    # - User.get_all(db) -> List[User]
    # - User.get_paginated(db, page, limit) -> Dict
    # - User.update(db, id, updates) -> User | None
    # - User.delete(db, id) -> bool
    # - User.count(db) -> int
    # - User.exists(db, id) -> bool

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, name={self.name})>"
