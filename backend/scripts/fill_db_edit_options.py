"""
Script to populate the edit_options table from JSON file.

This script reads edit options from edit_options_extracted_fully.json
and inserts them into the database.

Usage:
    python fill_db_edit_options.py

The script will:
1. Load edit options from the JSON file
2. Connect to the database
3. Insert all edit options into the edit_options table
4. Print a summary of inserted records
"""

import json
import asyncio
import sys
from pathlib import Path
from datetime import datetime, timezone

# Add parent directory to path to import src modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from src.models import EditOption
from src.core.config import settings


async def load_edit_options_from_json(json_file_path: str) -> dict:
    """
    Load edit options from JSON file.

    Args:
        json_file_path: Path to the JSON file

    Returns:
        Dictionary with structure: {category: {subject: [options]}}
    """
    with open(json_file_path, "r", encoding="utf-8") as f:
        return json.load(f)


async def populate_edit_options():
    """
    Populate the edit_options table from JSON file.

    This function:
    1. Loads data from JSON
    2. Creates database session
    3. Inserts all edit options
    4. Prints summary
    """
    # Get JSON file path
    json_file_path = Path(__file__).parent / "edit_options_extracted_fully.json"

    if not json_file_path.exists():
        print(f"❌ JSON file not found: {json_file_path}")
        return

    print(f"📖 Loading edit options from: {json_file_path}")

    # Load data from JSON
    data = await load_edit_options_from_json(str(json_file_path))

    # Create async engine and session
    engine = create_async_engine(settings.DATABASE_URL, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    try:
        async with async_session() as session:
            total_inserted = 0
            categories_processed = 0
            subjects_processed = 0
            now = datetime.now(timezone.utc)  # Use timezone-aware UTC datetime

            # Iterate through categories
            for category, subjects in data.items():
                categories_processed += 1
                print(f"\n📂 Processing category: {category}")

                # Iterate through subjects
                for subject, options in subjects.items():
                    subjects_processed += 1
                    print(
                        f"  📋 Processing subject: {subject} ({len(options)} options)"
                    )

                    # Iterate through options
                    for option in options:
                        try:
                            # Create EditOption instance
                            edit_option = EditOption(
                                category=category,
                                subject=subject,
                                title_en=option.get("titleEn", ""),
                                title_de=option.get("titleDe", ""),
                                description_en=option.get("descriptionEn", ""),
                                description_de=option.get("descriptionDe", ""),
                                prompt_en=option.get("promptEn", ""),
                                prompt_de=option.get("promptDe", ""),
                                icon=option.get("emoji", None),
                            )

                            # Add to session
                            session.add(edit_option)
                            total_inserted += 1

                            print(
                                f"    ✅ Added: {option.get('titleEn')} ({option.get('emoji')})"
                            )

                        except Exception as e:
                            print(
                                f"    ❌ Error adding option {option.get('titleEn')}: {str(e)}"
                            )

            # Commit all changes
            print(f"\n💾 Committing {total_inserted} records to database...")
            await session.commit()

            print(f"\n✅ Successfully populated edit_options table!")
            print(f"   📊 Summary:")
            print(f"      - Categories: {categories_processed}")
            print(f"      - Subjects: {subjects_processed}")
            print(f"      - Edit Options: {total_inserted}")

    except Exception as e:
        print(f"❌ Error populating database: {str(e)}")
        raise
    finally:
        await engine.dispose()


async def main():
    """Main entry point."""
    print("🚀 Starting edit_options table population...\n")
    await populate_edit_options()
    print("\n✨ Done!")


if __name__ == "__main__":
    asyncio.run(main())
