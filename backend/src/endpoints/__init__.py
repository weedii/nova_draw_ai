"""
API endpoints/routers for Nova Draw AI backend.

Each router handles HTTP requests for a specific domain.
Routers delegate business logic to service layer.

Usage:
    from endpoints import edit_option, tutorial
    app.include_router(edit_option.router)
    app.include_router(tutorial.router)
"""
