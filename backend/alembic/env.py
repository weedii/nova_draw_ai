"""
Alembic migration environment configuration.

This module configures Alembic to work with the Nova Draw AI database.
It handles:
1. Loading environment variables from .env
2. Importing SQLAlchemy models and Base
3. Configuring migration modes (online/offline)
4. Autogenerating migrations based on model changes

Key features:
- Loads DATABASE_URL from environment variables (Neon connection)
- Uses sync engine for migrations (correct approach even with async app)
- Supports both online and offline migration modes
- Automatically detects model changes for autogenerate

Usage:
    # Generate a new migration (autogenerate from model changes)
    alembic revision --autogenerate -m "add users table"

    # Apply all pending migrations
    alembic upgrade head

    # Rollback one migration
    alembic downgrade -1
"""

from logging.config import fileConfig
from sqlalchemy import engine_from_config
from sqlalchemy import pool
from alembic import context

import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Add the backend directory to the path so imports work correctly
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# Load environment variables from .env file
load_dotenv()

# Import models and Base from the correct location
# Note: We import all models to ensure they're registered with Base.metadata
from src.database.db import Base
from src.models import *

# Get the Alembic Config object
config = context.config

# Interpret the config file for Python logging
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Set the SQLAlchemy metadata for autogenerate support
# This tells Alembic what tables/columns to track
target_metadata = Base.metadata

# Override sqlalchemy.url with DATABASE_URL environment variable if present
# This allows us to use Neon connection string without hardcoding it
database_url = os.getenv("DATABASE_URL")
if database_url:
    # Convert async URL to sync URL for Alembic (migrations run synchronously)
    # postgresql+asyncpg://... -> postgresql://...
    sync_database_url = database_url.replace("postgresql+asyncpg://", "postgresql://")

    # Convert asyncpg SSL parameter to psycopg2 SSL parameter
    # asyncpg uses ?ssl=require, psycopg2 uses ?sslmode=require
    sync_database_url = sync_database_url.replace("?ssl=require", "?sslmode=require")

    config.set_main_option("sqlalchemy.url", sync_database_url)
else:
    # Fallback to default if DATABASE_URL not set
    print(
        "WARNING: DATABASE_URL not set in environment. Using default from alembic.ini"
    )


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode.

    This configures the context with just a URL
    and not an Engine, though an Engine is acceptable
    here as well.  By skipping the Engine creation
    we don't even need a DBAPI to be available.

    Calls to context.execute() here emit the given string to the
    script output.

    """
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode.

    In this scenario we need to create an Engine
    and associate a connection with the context.

    """
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
