"""
SQLAlchemy ORM models for Nova Draw AI application.

This module exports all database models:
- User: User accounts with authentication
- Tutorial: Drawing tutorials with metadata
- TutorialStep: Individual steps within a tutorial
- Drawing: User-created drawings
- Story: AI-generated stories from drawings
- EditOption: AI editing options for subjects (e.g., "Make it colorful")

All models use decorators for:
- @auditable: Automatic timestamp tracking and soft delete
- @crud_enabled: Automatic CRUD operations (create, read, update, delete)

Usage:
    from models import User, Tutorial, Drawing, Story, EditOption
    from database import get_db
    from sqlalchemy.ext.asyncio import AsyncSession

    # Using decorator-provided CRUD methods:
    async def get_user(db: AsyncSession, user_id: UUID):
        user = await User.get_by_id(db, user_id)
        return user

    # Creating a new user:
    async def create_user(db: AsyncSession, email: str, password: str):
        user = await User.create(db, email=email, password=password)
        return user
"""

from .user import User
from .tutorial import Tutorial
from .tutorial_step import TutorialStep
from .drawing import Drawing
from .story import Story
from .edit_option import EditOption

__all__ = ["User", "Tutorial", "TutorialStep", "Drawing", "Story", "EditOption"]
