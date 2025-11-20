"""
Service layer for Nova Draw AI backend.

Services contain business logic and are called by endpoints.
Each service handles a specific domain (e.g., EditOptionService for edit options).

Usage:
    from services.edit_option_service import EditOptionService
    from database import get_db

    response = await EditOptionService.get_edit_options_by_subject(db, "Animals", "dog")
"""
