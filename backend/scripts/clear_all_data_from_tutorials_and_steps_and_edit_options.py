"""
Script to clear all data from tutorials, tutorial_steps, and edit_options tables.

This script deletes all rows from the three tables:
- tutorials
- tutorial_steps
- edit_options

Usage:
    # From backend directory:
    python -m scripts.clear_all_data_from_tutorials_and_steps_and_edit_options

    # Or directly:
    python scripts/clear_all_data_from_tutorials_and_steps_and_edit_options.py
"""

import asyncio
import logging
import sys
from pathlib import Path

# Add backend directory to Python path
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import delete

from src.core.config import settings
from src.models import Tutorial, TutorialStep, EditOption

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


async def clear_all_data():
    """Delete all rows from tutorials, tutorial_steps, and edit_options tables."""

    # Create async engine
    engine = create_async_engine(settings.DATABASE_URL, echo=False)

    # Create async session factory
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    try:
        async with async_session() as session:
            logger.info("Starting data deletion...")

            # Delete from tutorial_steps first (foreign key dependency)
            logger.info("Deleting all tutorial_steps...")
            await session.execute(delete(TutorialStep))
            deleted_steps = await session.execute(delete(TutorialStep))
            logger.info(f"✓ Deleted tutorial_steps")

            # Delete from tutorials
            logger.info("Deleting all tutorials...")
            await session.execute(delete(Tutorial))
            logger.info(f"✓ Deleted tutorials")

            # Delete from edit_options
            logger.info("Deleting all edit_options...")
            await session.execute(delete(EditOption))
            logger.info(f"✓ Deleted edit_options")

            # Commit the transaction
            await session.commit()
            logger.info("\n✅ All data cleared successfully!")

    except Exception as e:
        logger.error(f"❌ Error clearing data: {str(e)}")
        raise
    finally:
        await engine.dispose()


def main():
    """Main function."""
    asyncio.run(clear_all_data())


if __name__ == "__main__":
    main()
