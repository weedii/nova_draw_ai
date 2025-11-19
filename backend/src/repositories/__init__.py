"""
Repository layer for Nova Draw AI backend.

Repositories provide custom query methods beyond basic CRUD operations.
Each model has a corresponding repository for specialized queries.

Usage:
    from repositories import UserRepository, DrawingRepository
    from database import get_db

    # Use decorator CRUD for basic operations
    user = await User.get_by_id(db, user_id)

    # Use repository for custom queries
    user = await UserRepository.find_by_email(db, email)
"""

from .user_repository import UserRepository
from .tutorial_repository import TutorialRepository
from .drawing_repository import DrawingRepository
from .story_repository import StoryRepository

__all__ = [
    "UserRepository",
    "TutorialRepository",
    "DrawingRepository",
    "StoryRepository",
]
