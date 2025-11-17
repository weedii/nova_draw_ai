"""
Database module exports for easy importing.

This module re-exports the main database components for convenient access:
- engine: Async SQLAlchemy engine connected to Neon
- async_session: Session factory for creating database sessions
- get_db: FastAPI dependency for injecting sessions into route handlers
- init_db: Function to initialize database tables
- cleanup_db: Function to drop all tables (development/testing only)

Usage:
    from database import engine, get_db, init_db
    from fastapi import Depends
    from sqlalchemy.ext.asyncio import AsyncSession
"""

from .db import engine, async_session, get_db, init_db, cleanup_db

__all__ = ["engine", "async_session", "get_db", "init_db", "cleanup_db"]
