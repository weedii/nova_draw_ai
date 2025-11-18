from sqlalchemy import Column, Integer, Text, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from database.db import Base


class TutorialStep(Base):
    __tablename__ = "tutorial_steps"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    tutorial_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tutorials.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    step_number = Column(Integer, nullable=False)
    instruction_en = Column(Text, nullable=False)
    instruction_de = Column(Text, nullable=False)
    image_url = Column(Text, nullable=False)
    created_at = Column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    tutorial = relationship("Tutorial", back_populates="steps")

    def __repr__(self):
        return f"<TutorialStep(id={self.id}, tutorial_id={self.tutorial_id}, step_number={self.step_number})>"
