"""
TutorialStep model for Nova Draw AI application.
Represents individual steps within a drawing tutorial.
"""

from sqlalchemy import Column, Integer, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid

from src.database.db import Base
from src.utils import auditable, crud_enabled


@crud_enabled
@auditable
class TutorialStep(Base):
    """
    TutorialStep model representing individual steps within a drawing tutorial.

    Each step contains instructions in multiple languages and an associated image.

    Decorators:
    - @auditable: Adds created_at, updated_at for audit trail
    - @crud_enabled: Adds CRUD operations (create, get_by_id, get_all, get_paginated, update, delete, count, exists)
    """

    __tablename__ = "tutorial_steps"

    # Primary key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)

    # Foreign key
    tutorial_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tutorials.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # Step information
    step_number = Column(Integer, nullable=False)
    instruction_en = Column(Text, nullable=False)
    instruction_de = Column(Text, nullable=False)
    image_url = Column(Text, nullable=False)

    # Relationships
    tutorial = relationship("Tutorial", back_populates="steps")

    # Note: created_at, updated_at are automatically added by @auditable
    #
    # CRUD operations added by @crud_enabled decorator:
    # - TutorialStep.create(db, **kwargs) -> TutorialStep
    # - TutorialStep.get_by_id(db, id) -> TutorialStep | None
    # - TutorialStep.get_all(db) -> List[TutorialStep]
    # - TutorialStep.get_paginated(db, page, limit) -> Dict
    # - TutorialStep.update(db, id, updates) -> TutorialStep | None
    # - TutorialStep.delete(db, id) -> bool
    # - TutorialStep.count(db) -> int
    # - TutorialStep.exists(db, id) -> bool

    def __repr__(self):
        return f"<TutorialStep(id={self.id}, tutorial_id={self.tutorial_id}, step_number={self.step_number})>"
