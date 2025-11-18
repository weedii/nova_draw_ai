from sqlalchemy import Column, String, Integer, Text, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from database.db import Base


class Tutorial(Base):
    __tablename__ = "tutorials"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    category = Column(String(100), nullable=False, index=True)
    subject = Column(String(100), nullable=False)
    total_steps = Column(Integer, nullable=False)
    thumbnail_url = Column(Text, nullable=True)
    description_en = Column(Text, nullable=True)
    description_de = Column(Text, nullable=True)
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
    steps = relationship(
        "TutorialStep", back_populates="tutorial", cascade="all, delete-orphan"
    )
    drawings = relationship("Drawing", back_populates="tutorial")

    def __repr__(self):
        return f"<Tutorial(id={self.id}, category={self.category}, subject={self.subject})>"
