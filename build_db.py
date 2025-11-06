#!/usr/bin/env python3
"""
Database Builder Script for Nova Draw AI

This script scans the local 'data/' folder structure and generates a structured 'db.json' file.
The folder structure is:
- data/
  - category/ (animals, nature, objects, etc.)
    - item/ (dog, cat, star, etc.)
      - drawing_folder/ (timestamped folders like cat_20251105_113952)
        - step_XX_item.jpeg (drawing step images)
        - steps (English instructions)
        - step_de (German instructions)
"""

import os
import json
import re
from pathlib import Path
from typing import Dict, List, Optional


def load_text_file(file_path: Path) -> List[str]:
    """
    Load text content from a file and parse into individual steps.

    Args:
        file_path: Path to the text file

    Returns:
        List of step strings with prefixes removed, or empty list if file doesn't exist
    """
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read().strip()

        if not content:
            return []

        # Split by lines and process each step
        lines = content.split("\n")
        steps = []

        for line in lines:
            line = line.strip()
            if not line:
                continue

            # Remove step prefixes like "🔹Step 1:", "🔹Schritt 1:", "Step 1:", "Schritt 1:"
            # Handle both with and without emoji
            prefixes_to_remove = [
                r"🔹\s*Step\s+\d+:\s*",
                r"🔹\s*Schritt\s+\d+:\s*",
                r"Step\s+\d+:\s*",
                r"Schritt\s+\d+:\s*",
            ]

            cleaned_line = line
            for prefix_pattern in prefixes_to_remove:
                cleaned_line = re.sub(
                    prefix_pattern, "", cleaned_line, flags=re.IGNORECASE
                )

            if cleaned_line:
                steps.append(cleaned_line)

        return steps

    except (FileNotFoundError, UnicodeDecodeError, PermissionError):
        # Gracefully handle missing files or encoding issues
        return []


def get_image_files(drawing_folder: Path) -> List[str]:
    """
    Get all .jpeg/.jpg image files in a drawing folder, sorted by filename.

    Args:
        drawing_folder: Path to the drawing folder

    Returns:
        List of relative paths to image files
    """
    image_extensions = {".jpg", ".jpeg"}
    image_files = []

    try:
        for file_path in drawing_folder.iterdir():
            if file_path.is_file() and file_path.suffix.lower() in image_extensions:
                # Convert to relative path from project root
                # Get relative path from current working directory
                try:
                    relative_path = file_path.relative_to(Path.cwd())
                    # Convert to forward slashes for consistency
                    relative_path_str = str(relative_path).replace("\\", "/")
                    image_files.append(relative_path_str)
                except ValueError:
                    # If relative_to fails, use the absolute path as fallback
                    relative_path_str = str(file_path).replace("\\", "/")
                    image_files.append(relative_path_str)
    except (PermissionError, OSError):
        # Handle permission or other OS errors gracefully
        pass

    # Sort by filename to ensure consistent ordering
    return sorted(image_files)


def process_drawing_folder(drawing_folder: Path) -> Optional[Dict]:
    """
    Process a single drawing folder and extract its data.

    Args:
        drawing_folder: Path to the drawing folder

    Returns:
        Dictionary with steps and images, or None if folder is invalid
    """
    if not drawing_folder.is_dir():
        return None

    # Load text files
    steps_en_path = drawing_folder / "steps"
    steps_de_path = drawing_folder / "step_de"

    steps_en = load_text_file(steps_en_path)
    steps_de = load_text_file(steps_de_path)

    # Get image files
    images = get_image_files(drawing_folder)

    # Only include if we have at least some content
    if not steps_en and not steps_de and not images:
        return None

    return {"steps_en": steps_en, "steps_de": steps_de, "images": images}


def process_item_folder(item_folder: Path) -> Dict:
    """
    Process an item folder (e.g., 'cat', 'dog') and extract all its drawings.

    Args:
        item_folder: Path to the item folder

    Returns:
        Dictionary mapping drawing names to their data
    """
    item_data = {}

    try:
        # Get all subdirectories (drawing folders)
        drawing_folders = [d for d in item_folder.iterdir() if d.is_dir()]

        # Sort by folder name for consistent ordering
        drawing_folders.sort(key=lambda x: x.name)

        for i, drawing_folder in enumerate(drawing_folders, 1):
            drawing_data = process_drawing_folder(drawing_folder)
            if drawing_data:
                # Use drawing_X format for consistency
                drawing_key = f"drawing_{i}"
                item_data[drawing_key] = drawing_data

    except (PermissionError, OSError):
        # Handle permission or other OS errors gracefully
        pass

    return item_data


def process_category_folder(category_folder: Path) -> Dict:
    """
    Process a category folder (e.g., 'animals', 'nature') and extract all its items.

    Args:
        category_folder: Path to the category folder

    Returns:
        Dictionary mapping item names to their data
    """
    category_data = {}

    try:
        # Get all subdirectories (item folders)
        item_folders = [d for d in category_folder.iterdir() if d.is_dir()]

        # Sort by folder name for consistent ordering
        item_folders.sort(key=lambda x: x.name)

        for item_folder in item_folders:
            item_name = item_folder.name
            item_data = process_item_folder(item_folder)

            # Only include items that have drawings
            if item_data:
                category_data[item_name] = item_data

    except (PermissionError, OSError):
        # Handle permission or other OS errors gracefully
        pass

    return category_data


def find_data_folder() -> Optional[Path]:
    """
    Find the data folder, checking both current directory and parent directories.

    Returns:
        Path to the data folder, or None if not found
    """
    current_dir = Path.cwd()

    # Check current directory first
    data_path = current_dir / "data"
    if data_path.exists() and data_path.is_dir():
        return data_path

    # Check parent directories (useful if script is in backend/ folder)
    for parent in current_dir.parents:
        data_path = parent / "data"
        if data_path.exists() and data_path.is_dir():
            return data_path

    return None


def build_database() -> Dict:
    """
    Build the complete database by scanning the data folder structure.

    Returns:
        Complete database dictionary
    """
    data_folder = find_data_folder()

    if not data_folder:
        print("Error: 'data/' folder not found!")
        print(
            "Make sure the 'data/' folder exists in the current directory or a parent directory."
        )
        return {}

    print(f"Found data folder: {data_folder}")

    database = {}

    try:
        # Get all category folders
        category_folders = [d for d in data_folder.iterdir() if d.is_dir()]

        # Sort by folder name for consistent ordering
        category_folders.sort(key=lambda x: x.name)

        for category_folder in category_folders:
            category_name = category_folder.name
            print(f"Processing category: {category_name}")

            category_data = process_category_folder(category_folder)

            # Only include categories that have items
            if category_data:
                database[category_name] = category_data

                # Print summary for this category
                total_drawings = sum(
                    len(item_data) for item_data in category_data.values()
                )
                print(
                    f"  - Found {len(category_data)} items with {total_drawings} total drawings"
                )
            else:
                print(f"  - No valid items found in {category_name}")

    except (PermissionError, OSError) as e:
        print(f"Error accessing data folder: {e}")
        return {}

    return database


def save_database(database: Dict, output_file: str = "db.json") -> bool:
    """
    Save the database to a JSON file.

    Args:
        database: The database dictionary to save
        output_file: Output filename (default: db.json)

    Returns:
        True if successful, False otherwise
    """
    try:
        with open(output_file, "w", encoding="utf-8") as f:
            json.dump(database, f, indent=2, ensure_ascii=False)
        return True
    except (PermissionError, OSError) as e:
        print(f"Error saving database: {e}")
        return False


def main():
    """
    Main function to build and save the database.
    """
    print("Nova Draw AI - Database Builder")
    print("=" * 40)

    # Build the database
    print("Scanning data folder structure...")
    database = build_database()

    if not database:
        print("No data found or error occurred. Database not created.")
        return

    # Save to JSON file
    print(f"\nSaving database to db.json...")
    if save_database(database):
        print("✅ Database successfully built and saved to 'db.json'!")

        # Print summary statistics
        total_categories = len(database)
        total_items = sum(len(category) for category in database.values())
        total_drawings = sum(
            len(item) for category in database.values() for item in category.values()
        )

        print(f"\nDatabase Summary:")
        print(f"  📁 Categories: {total_categories}")
        print(f"  🎨 Items: {total_items}")
        print(f"  📚 Drawings: {total_drawings}")

    else:
        print("❌ Failed to save database.")


if __name__ == "__main__":
    main()
