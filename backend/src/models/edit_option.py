"""
EditOption model for Nova Draw AI application.

Represents AI editing options available for a specific subject (e.g., 'Make it colorful', 'Add sunglasses').
Each edit option is linked to a category and subject, allowing kids to choose how they want their drawing edited.

Why this table exists:
- Decouples edit options from tutorials (multiple tutorials can share the same edit options)
- Allows dynamic management of edit options without modifying tutorials
- Enables category/subject-based filtering of available edits
"""

from sqlalchemy import Column, String, Text
from sqlalchemy.dialects.postgresql import UUID
import uuid

from src.database.db import Base
from src.utils import auditable, crud_enabled


@crud_enabled
@auditable
class EditOption(Base):
    """
    EditOption model representing an AI editing option for a subject.

    Each edit option contains:
    - category: The category this option belongs to (e.g., 'Animals')
    - subject: The subject this option is for (e.g., 'dog', 'cat')
    - title_en/title_de: Localized titles for the edit option
    - description_en/description_de: Localized descriptions
    - prompt_en/prompt_de: Localized prompts to pass to the AI for image editing
    - icon: Emoji or icon identifier for UI display

    Decorators:
    - @auditable: Automatically adds created_at, updated_at for audit trail
    - @crud_enabled: Automatically adds CRUD operations (create, get_by_id, get_all, get_paginated, update, delete, count, exists)

    Example:
        edit_option = EditOption(
            category="Animals",
            subject="dog",
            title_en="Make it colorful",
            title_de="Mach es farbig",
            description_en="Add vibrant colors to your drawing",
            description_de="Füge lebendige Farben zu deiner Zeichnung hinzu",
            prompt_en="Make the drawing colorful with vibrant colors",
            prompt_de="Mache die Zeichnung mit lebendigen Farben farbig",
            icon="🎨"
        )
    """

    __tablename__ = "edit_options"

    # Primary key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)

    # Foreign key reference (category + subject combination)
    # Note: We use string columns instead of FK to maintain flexibility
    # This allows edit options to exist independently of tutorials
    category = Column(String(100), nullable=False, index=True)
    subject = Column(String(100), nullable=False, index=True)

    # Localized titles and descriptions
    title_en = Column(String(100), nullable=False)
    title_de = Column(String(100), nullable=False)
    description_en = Column(Text, nullable=False)
    description_de = Column(Text, nullable=False)

    # Localized prompts for AI image editing
    prompt_en = Column(Text, nullable=False)
    prompt_de = Column(Text, nullable=False)

    # UI representation
    icon = Column(String(32), nullable=True)  # Emoji or icon name (e.g., "🎨", "✨")

    # Note: created_at, updated_at are automatically added by @auditable
    #
    # CRUD operations added by @crud_enabled decorator:
    # - EditOption.create(db, **kwargs) -> EditOption
    # - EditOption.get_by_id(db, id) -> EditOption | None
    # - EditOption.get_all(db) -> List[EditOption]
    # - EditOption.get_paginated(db, page, limit) -> Dict
    # - EditOption.update(db, id, updates) -> EditOption | None
    # - EditOption.delete(db, id) -> bool
    # - EditOption.count(db) -> int
    # - EditOption.exists(db, id) -> bool

    def __repr__(self):
        return f"<EditOption(id={self.id}, category={self.category}, subject={self.subject}, title_en={self.title_en})>"
