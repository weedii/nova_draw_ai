"""
Script to populate category emojis, colors, and subject emojis in the tutorials table.

This script reads the static Flutter drawing data and updates the database with:
- category_emoji: Emoji for the category (e.g., "🐶" for Animals)
- category_color: Hex color for the category (e.g., "#FF6B6B")
- subject_emoji: Emoji for the drawing/subject (e.g., "🐕" for Dog)

Usage:
    python populate_emojis_and_colors.py

The script will:
1. Parse the Flutter drawing data structure
2. Extract category emojis and colors
3. Extract subject emojis
4. Update the tutorials table with the extracted data
5. Print a summary of changes
"""

import asyncio
import os
import sys
from pathlib import Path

# Add the backend directory to the path so imports work correctly
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from src.core.config import settings
from src.models.tutorial import Tutorial


# Flutter color mapping to hex values
# These are extracted from AppColors in the Flutter app
FLUTTER_COLORS = {
    "AppColors.primary": "#4DA6FF",  # Sky Blue (primary)
    "AppColors.secondary": "#FFD93D",  # Bright Yellow (secondary)
    "AppColors.accent": "#FF7EB9",  # Soft Pink (accent)
    "AppColors.success": "#35E8A1",  # Mint Green (success)
    "AppColors.error": "#FF6B6B",  # Error/Red
    "AppColors.primaryDark": "#3D8BFF",  # Darker primary
    "AppColors.primaryLight": "#80C1FF",  # Lighter primary
    "AppColors.background": "#FFF9E6",  # Light cream
    "AppColors.border": "#E2E8F0",  # Subtle gray
    "AppColors.textDark": "#2D3748",  # Dark text
    "AppColors.white": "#FFFFFF",  # White
}

# Mapping of category IDs to their emoji and color
CATEGORY_DATA = {
    "animals": {
        "emoji": "🐶",
        "color": "#4DA6FF",  # AppColors.primary
    },
    "objects": {
        "emoji": "⚽",
        "color": "#FFD93D",  # AppColors.secondary
    },
    "nature": {
        "emoji": "🌳",
        "color": "#35E8A1",  # AppColors.success
    },
    "vehicles": {
        "emoji": "🚗",
        "color": "#3D8BFF",  # AppColors.primaryDark
    },
    "food": {
        "emoji": "🍎",
        "color": "#FF6B6B",  # AppColors.error
    },
    "characters": {
        "emoji": "👑",
        "color": "#FF7EB9",  # AppColors.accent
    },
}

# Mapping of subject IDs to their emoji
SUBJECT_DATA = {
    # Animals
    "dog": "🐕",
    "cat": "🐱",
    "fish": "🐠",
    "elephant": "🐘",
    # Objects
    "house": "🏠",
    "ball": "⚽",
    "star": "⭐",
    # Nature
    "tree": "🌳",
    "flower": "🌸",
    "sun": "☀️",
    # Vehicles
    "car": "🚗",
    "airplane": "✈️",
    # Food
    "apple": "🍎",
    "pizza": "🍕",
    # Characters
    "princess": "👸",
    "king": "🤴",
    "robot": "🤖",
}


async def populate_emojis_and_colors():
    """
    Populate the tutorials table with emojis and colors.
    """
    # Create async engine
    engine = create_async_engine(
        settings.DATABASE_URL,
        echo=False,
        future=True,
    )

    # Create session factory
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    try:
        async with async_session() as session:
            print("🔄 Starting emoji and color population...")
            print()

            # Get all tutorials
            result = await session.execute(select(Tutorial))
            tutorials = result.scalars().all()

            if not tutorials:
                print("❌ No tutorials found in the database.")
                return

            print(f"📚 Found {len(tutorials)} tutorials in the database.")
            print()

            updated_count = 0
            updates_summary = []

            for tutorial in tutorials:
                category = tutorial.category.lower() if tutorial.category else None
                subject = tutorial.subject.lower() if tutorial.subject else None

                # Get category data
                category_data = CATEGORY_DATA.get(category)
                subject_emoji = SUBJECT_DATA.get(subject)

                if category_data and subject_emoji:
                    # Update the tutorial
                    tutorial.category_emoji = category_data["emoji"]
                    tutorial.category_color = category_data["color"]
                    tutorial.subject_emoji = subject_emoji

                    updates_summary.append(
                        {
                            "category": tutorial.category,
                            "subject": tutorial.subject,
                            "category_emoji": category_data["emoji"],
                            "category_color": category_data["color"],
                            "subject_emoji": subject_emoji,
                        }
                    )

                    updated_count += 1

            # Commit changes
            if updated_count > 0:
                await session.commit()
                print(f"✅ Successfully updated {updated_count} tutorials!")
                print()
                print("📋 Update Summary:")
                print("-" * 80)

                for update_info in updates_summary:
                    print(
                        f"  Category: {update_info['category']:15} | Subject: {update_info['subject']:15}"
                    )
                    print(
                        f"    Category Emoji: {update_info['category_emoji']}  | Category Color: {update_info['category_color']}"
                    )
                    print(f"    Subject Emoji: {update_info['subject_emoji']}")
                    print()
            else:
                print("⚠️  No tutorials were updated. Check category and subject names.")

    except Exception as e:
        print(f"❌ Error: {e}")
        raise
    finally:
        await engine.dispose()


async def main():
    """Main entry point."""
    print()
    print("=" * 80)
    print("  Emoji and Color Population Script")
    print("=" * 80)
    print()

    await populate_emojis_and_colors()

    print()
    print("=" * 80)
    print("  Done!")
    print("=" * 80)
    print()


if __name__ == "__main__":
    asyncio.run(main())
