"""
Script to populate Tutorial and TutorialStep tables from JSON file.

This script reads from to_fill_db.json and populates the database with:
- Tutorial records (one per tutorial_key like cat_1, dog_2, etc.)
- TutorialStep records (one per step in each tutorial)

Usage:
    python fill_db.py

The script will:
1. Load the JSON file
2. Parse categories, subjects, and tutorials
3. Create Tutorial records with category, subject, and total_steps
4. Create TutorialStep records with step_number, instructions, and image URLs
5. Commit all records to the database
"""

import asyncio
import json
from pathlib import Path
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

# Add backend to path
import sys

sys.path.insert(0, str(Path(__file__).parent.parent))

from src.database.db import async_session, init_db
from src.models.tutorial import Tutorial
from src.models.tutorial_step import TutorialStep


async def load_json_data(json_path: str) -> dict:
    """Load and parse the JSON file."""
    with open(json_path, "r", encoding="utf-8") as f:
        return json.load(f)


async def fill_database():
    """Main function to fill the database."""

    # Initialize database (create tables if they don't exist)
    # print("Initializing database...")
    # await init_db()
    # print("✓ Database initialized\n")

    # Load JSON data
    json_path = Path(__file__).parent / "to_fill_db_tutorials.json"
    print(f"Loading JSON from: {json_path}")
    data = await load_json_data(str(json_path))
    print("✓ JSON loaded\n")

    # Create async session
    async with async_session() as session:
        tutorial_count = 0
        step_count = 0

        # Iterate through categories
        for category, category_data in data.items():
            # Extract bilingual category names
            category_en = category_data.get("category_en", category)
            category_de = category_data.get("category_de", category)
            print(f"Processing category: {category_en} ({category_de})")

            # Iterate through subjects (e.g., cat, dog, elephant)
            for subject, subject_data in category_data.items():
                # Skip metadata fields
                if subject in ["category_en", "category_de"]:
                    continue

                # Extract bilingual subject names
                subject_en = (
                    subject_data.get("subject_en", subject)
                    if isinstance(subject_data, dict)
                    else subject
                )
                subject_de = (
                    subject_data.get("subject_de", subject)
                    if isinstance(subject_data, dict)
                    else subject
                )

                # Get tutorials dict
                tutorials = subject_data if isinstance(subject_data, dict) else {}
                print(f"  Subject: {subject_en} ({subject_de})")

                # Iterate through tutorials (e.g., cat_1, cat_2, cat_3)
                for tutorial_key, steps in tutorials.items():
                    # Skip metadata fields
                    if tutorial_key in ["subject_en", "subject_de"]:
                        continue

                    # Create Tutorial record
                    tutorial = Tutorial(
                        category_en=category_en,
                        category_de=category_de,
                        subject_en=subject_en,
                        subject_de=subject_de,
                        total_steps=len(steps),
                        thumbnail_url=(
                            steps[0]["image"] if steps else None
                        ),  # Use first step image as thumbnail
                        description_en=f"Learn to draw {subject_en}",
                        description_de=f"Lerne, {subject_de} zu zeichnen",
                    )

                    session.add(tutorial)
                    await session.flush()  # Flush to get the tutorial ID

                    tutorial_count += 1

                    # Create TutorialStep records for each step
                    for step_number, step_data in enumerate(steps, start=1):
                        tutorial_step = TutorialStep(
                            tutorial_id=tutorial.id,
                            step_number=step_number,
                            instruction_en=step_data["step_en"],
                            instruction_de=step_data["step_de"],
                            image_url=step_data["image"],
                        )

                        session.add(tutorial_step)
                        step_count += 1

                    print(f"    ✓ {tutorial_key} ({len(steps)} steps)")

        # Commit all changes
        print(
            f"\nCommitting {tutorial_count} tutorials and {step_count} steps to database..."
        )
        await session.commit()
        print("✓ All data committed successfully!\n")

        # Verify the data
        print("Verifying data...")
        result = await session.execute(select(Tutorial))
        tutorials = result.scalars().all()
        print(f"✓ Total tutorials in database: {len(tutorials)}")

        result = await session.execute(select(TutorialStep))
        all_steps = result.scalars().all()
        print(f"✓ Total steps in database: {len(all_steps)}\n")

        # Show summary by category
        print("Summary by category:")
        for category, subjects in data.items():
            total_tutorials = 0
            total_steps = 0

            # Skip metadata fields (category_en, category_de)
            for subject_key, subject_data in subjects.items():
                if subject_key in ["category_en", "category_de"]:
                    continue

                # Skip metadata fields (subject_en, subject_de) and count tutorials
                for tutorial_key, tutorial_data in subject_data.items():
                    if tutorial_key in ["subject_en", "subject_de"]:
                        continue

                    # tutorial_data is a list of steps
                    if isinstance(tutorial_data, list):
                        total_tutorials += 1
                        total_steps += len(tutorial_data)

            print(f"  {category}: {total_tutorials} tutorials, {total_steps} steps")


async def main():
    """Entry point."""
    try:
        await fill_database()
        print("\n✅ Database fill completed successfully!")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(main())
