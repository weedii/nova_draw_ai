from sqlalchemy import Column, String, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from database.db import Base


class Drawing(Base):
    __tablename__ = "drawings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
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
    uploaded_image_url = Column(String, nullable=True)
    edited_images_urls = Column(ARRAY(String), nullable=True)
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
    user = relationship("User", back_populates="drawings")
    tutorial = relationship("Tutorial", back_populates="drawings")
    stories = relationship("Story", back_populates="drawing")

    def __repr__(self):
        return f"<Drawing(id={self.id}, user_id={self.user_id}, tutorial_id={self.tutorial_id})>"
