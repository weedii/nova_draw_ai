"""
Database configuration and session management for async SQLAlchemy with Neon PostgreSQL.

This module provides:
- Async SQLAlchemy engine configured for Neon
- Async session factory for database operations
- FastAPI dependency injection for database sessions
- Database initialization and cleanup utilities

The database URL is loaded from environment variables (DATABASE_URL) via core.config.Settings.
For Neon, the URL format is: postgresql+asyncpg://user:password@host/dbname?sslmode=require

Usage:
    from database import engine, async_session, get_db
    from fastapi import Depends
    from sqlalchemy.ext.asyncio import AsyncSession

    @app.get("/items")
    async def get_items(db: AsyncSession = Depends(get_db)):
        result = await db.execute(...)
        return result.scalars().all()
"""

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from core.config import settings
from sqlalchemy.orm import declarative_base

# Base class for all models
Base = declarative_base()

# Database URL from environment variable (loaded via Settings from .env)
DATABASE_URL = settings.DATABASE_URL

# Create async engine for Neon PostgreSQL
# asyncpg is the async driver for PostgreSQL
# pool_pre_ping=True ensures connections are alive before use
# echo=False (set to True for SQL query logging during development)
engine = create_async_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    echo=False,
)

# Create async session factory
# This factory creates new AsyncSession instances for each request
async_session = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


async def get_db():
    """
    FastAPI dependency for injecting database sessions into route handlers.

    Yields an AsyncSession instance for the duration of the request.
    Automatically closes the session when done.

    Usage:
        @app.get("/items")
        async def get_items(db: AsyncSession = Depends(get_db)):
            result = await db.execute(select(Item))
            return result.scalars().all()
    """
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()


async def init_db():
    """
    Initialize database by creating all tables defined in models.

    This function:
    1. Connects to the database
    2. Creates all tables based on Base.metadata
    3. Closes the connection

    Should be called once during application startup if using Alembic migrations,
    or as a one-time setup script.

    Note: When using Alembic for migrations, you typically don't call this directly.
    Instead, run: alembic upgrade head
    """
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def cleanup_db():
    """
    Drop all tables from the database.

    WARNING: This is destructive and should only be used for testing/development.

    This function:
    1. Connects to the database
    2. Drops all tables defined in Base.metadata
    3. Closes the connection
    """
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


__all__ = ["engine", "async_session", "get_db", "init_db", "cleanup_db", "Base"]
