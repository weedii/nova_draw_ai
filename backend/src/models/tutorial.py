"""
Tutorial model for Nova Draw AI application.
Represents drawing tutorials with step-by-step instructions.
"""

from sqlalchemy import Column, String, Integer, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid

from src.database.db import Base
from src.utils import auditable, crud_enabled


@crud_enabled
@auditable
class Tutorial(Base):
    """
    Tutorial model representing drawing tutorials in the Nova Draw AI application.

    Stores tutorial metadata and relationships to tutorial steps and user drawings.

    Decorators:
    - @auditable: Adds created_at, updated_at for audit trail
    - @crud_enabled: Adds CRUD operations (create, get_by_id, get_all, get_paginated, update, delete, count, exists)
    """

    __tablename__ = "tutorials"

    # Primary key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)

    # Tutorial information
    category = Column(String(100), nullable=False, index=True)
    category_emoji = Column(
        String(10), nullable=False, default="🎨"
    )  # Emoji for category (e.g., "🐶", "🌳")
    category_color = Column(
        String(7), nullable=False, default="#FF6B6B"
    )  # Hex color for category (e.g., "#FF6B6B")

    subject = Column(String(100), nullable=False)
    subject_emoji = Column(
        String(10), nullable=False, default="✏️"
    )  # Emoji for subject/drawing (e.g., "🐕", "🐱")

    total_steps = Column(Integer, nullable=False)
    thumbnail_url = Column(Text, nullable=True)
    description_en = Column(Text, nullable=True)
    description_de = Column(Text, nullable=True)

    # Relationships
    steps = relationship(
        "TutorialStep", back_populates="tutorial", cascade="all, delete-orphan"
    )
    drawings = relationship("Drawing", back_populates="tutorial")

    # Note: created_at, updated_at are automatically added by @auditable
    #
    # CRUD operations added by @crud_enabled decorator:
    # - Tutorial.create(db, **kwargs) -> Tutorial
    # - Tutorial.get_by_id(db, id) -> Tutorial | None
    # - Tutorial.get_all(db) -> List[Tutorial]
    # - Tutorial.get_paginated(db, page, limit) -> Dict
    # - Tutorial.update(db, id, updates) -> Tutorial | None
    # - Tutorial.delete(db, id) -> bool
    # - Tutorial.count(db) -> int
    # - Tutorial.exists(db, id) -> bool

    def __repr__(self):
        return f"<Tutorial(id={self.id}, category={self.category} {self.category_icon}, subject={self.subject} {self.subject_emoji})>"
