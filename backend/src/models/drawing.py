"""
Drawing model for Nova Draw AI application.
Represents user-created drawings (uploaded and edited).
"""

from sqlalchemy import Column, String, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from sqlalchemy.orm import relationship
import uuid

from database.db import Base
from utils import auditable, crud_enabled


@crud_enabled
@auditable
class Drawing(Base):
    """
    Drawing model representing user-created drawings in the Nova Draw AI application.

    Stores references to uploaded and edited images, linked to users and tutorials.

    Decorators:
    - @auditable: Adds created_at, updated_at for audit trail
    - @crud_enabled: Adds CRUD operations (create, get_by_id, get_all, get_paginated, update, delete, count, exists)
    """

    __tablename__ = "drawings"

    # Primary key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)

    # Foreign keys
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    tutorial_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tutorials.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    # Drawing information
    uploaded_image_url = Column(String, nullable=True)
    edited_images_urls = Column(ARRAY(String), nullable=True)

    # Relationships
    user = relationship("User", back_populates="drawings")
    tutorial = relationship("Tutorial", back_populates="drawings")
    stories = relationship("Story", back_populates="drawing")

    # Note: created_at, updated_at are automatically added by @auditable
    #
    # CRUD operations added by @crud_enabled decorator:
    # - Drawing.create(db, **kwargs) -> Drawing
    # - Drawing.get_by_id(db, id) -> Drawing | None
    # - Drawing.get_all(db) -> List[Drawing]
    # - Drawing.get_paginated(db, page, limit) -> Dict
    # - Drawing.update(db, id, updates) -> Drawing | None
    # - Drawing.delete(db, id) -> bool
    # - Drawing.count(db) -> int
    # - Drawing.exists(db, id) -> bool

    def __repr__(self):
        return f"<Drawing(id={self.id}, user_id={self.user_id}, tutorial_id={self.tutorial_id})>"
