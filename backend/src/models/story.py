"""
Story model for Nova Draw AI application.
Represents AI-generated stories from user drawings.
"""

from sqlalchemy import Column, String, Boolean, Integer, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid

from database.db import Base
from utils import auditable, crud_enabled


@crud_enabled
@auditable
class Story(Base):
    """
    Story model representing AI-generated stories from user drawings.

    Stores story content in multiple languages, linked to users and drawings.

    Decorators:
    - @auditable: Adds created_at, updated_at for audit trail
    - @crud_enabled: Adds CRUD operations (create, get_by_id, get_all, get_paginated, update, delete, count, exists)
    """

    __tablename__ = "stories"

    # Primary key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)

    # Foreign keys
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    drawing_id = Column(
        UUID(as_uuid=True),
        ForeignKey("drawings.id", ondelete="SET NULL"),
        nullable=True,
    )

    # Story information
    title = Column(String(200), nullable=False)
    story_text_en = Column(String, nullable=False)
    story_text_de = Column(String, nullable=False)
    image_url = Column(String, nullable=False)
    is_favorite = Column(Boolean, default=False, index=True)
    generation_time_ms = Column(Integer, nullable=True)

    # Relationships
    user = relationship("User", back_populates="stories")
    drawing = relationship("Drawing", back_populates="stories")

    # Note: created_at, updated_at are automatically added by @auditable
    #
    # CRUD operations added by @crud_enabled decorator:
    # - Story.create(db, **kwargs) -> Story
    # - Story.get_by_id(db, id) -> Story | None
    # - Story.get_all(db) -> List[Story]
    # - Story.get_paginated(db, page, limit) -> Dict
    # - Story.update(db, id, updates) -> Story | None
    # - Story.delete(db, id) -> bool
    # - Story.count(db) -> int
    # - Story.exists(db, id) -> bool

    def __repr__(self):
        return f"<Story(id={self.id}, user_id={self.user_id}, title={self.title})>"
