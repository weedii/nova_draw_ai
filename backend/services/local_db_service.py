import json
import base64
import random
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from PIL import Image
from io import BytesIO


class LocalDatabaseService:
    """Service for loading and serving drawing tutorials from local database"""

    def __init__(self, db_path: str = "db.json"):
        self.db_path = Path(db_path)
        self.database = self._load_database()

    def _load_database(self) -> Dict:
        """Load the local database from JSON file"""
        try:
            with open(self.db_path, "r", encoding="utf-8") as f:
                return json.load(f)
        except FileNotFoundError:
            raise FileNotFoundError(f"Database file not found: {self.db_path}")
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON in database file: {e}")

    def get_available_subjects(self) -> Dict[str, List[str]]:
        """Get all available subjects organized by category"""
        subjects = {}
        for category, items in self.database.items():
            subjects[category] = list(items.keys())
        return subjects

    def find_subject(self, subject_name: str) -> Optional[Tuple[str, str, Dict]]:
        """
        Find a subject in the database (case-insensitive).
        Returns (category, subject_key, subject_data) or None if not found.
        """
        subject_lower = subject_name.lower().strip()

        for category, items in self.database.items():
            for item_key, item_data in items.items():
                if item_key.lower() == subject_lower:
                    return category, item_key, item_data

        return None

    def get_tutorial_data(self, subject: str) -> Optional[Dict]:
        """
        Get tutorial data for a specific subject.
        Returns a random drawing variation if multiple exist.
        """
        result = self.find_subject(subject)
        if not result:
            return None

        category, subject_key, subject_data = result

        # Get all available drawings for this subject
        drawings = list(subject_data.keys())
        if not drawings:
            return None

        # Select a random drawing variation
        selected_drawing = random.choice(drawings)
        drawing_data = subject_data[selected_drawing]

        return {
            "category": category,
            "subject": subject_key,
            "drawing_id": selected_drawing,
            "steps_en": drawing_data.get("steps_en", []),
            "steps_de": drawing_data.get("steps_de", []),
            "images": drawing_data.get("images", []),
        }

    def _image_to_base64(self, image_path: str) -> str:
        """Convert image file to base64 string"""
        try:
            # Convert relative path to absolute path
            if not Path(image_path).is_absolute():
                # The image paths in db.json are relative to project root
                # db.json is in backend/, so we need to go up one level to get to project root
                if self.db_path.is_absolute():
                    # If db_path is absolute, get its parent (backend dir) then go up one more level
                    project_root = self.db_path.parent.parent
                else:
                    # If db_path is relative (like "db.json"), assume we're in backend/ and go up one level
                    project_root = Path.cwd().parent
                full_path = project_root / image_path
            else:
                full_path = Path(image_path)

            if not full_path.exists():
                raise FileNotFoundError(f"Image file not found: {full_path}")

            # Load and convert image to base64
            with Image.open(full_path) as img:
                # Convert to RGB if necessary
                if img.mode != "RGB":
                    img = img.convert("RGB")

                # Convert to base64
                buffered = BytesIO()
                img.save(buffered, format="PNG")
                img_base64 = base64.b64encode(buffered.getvalue()).decode("utf-8")

                return img_base64

        except Exception as e:
            print(f"Error converting image {image_path} to base64: {e}")
            # Return a placeholder base64 image (1x1 white pixel PNG)
            return "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="

    def get_tutorial_with_base64_images(self, subject: str) -> Optional[Dict]:
        """
        Get tutorial data with images converted to base64.
        Returns data in the same format as the AI-generated tutorials.
        """
        tutorial_data = self.get_tutorial_data(subject)
        if not tutorial_data:
            return None

        steps_en = tutorial_data["steps_en"]
        steps_de = tutorial_data["steps_de"]
        image_paths = tutorial_data["images"]

        # Ensure we have the same number of steps and images
        min_length = min(len(steps_en), len(steps_de), len(image_paths))

        if min_length == 0:
            return None

        # Create tutorial steps with base64 images
        tutorial_steps = []
        for i in range(min_length):
            # Convert image to base64
            base64_image = self._image_to_base64(image_paths[i])

            tutorial_steps.append(
                {
                    "step_en": steps_en[i],
                    "step_de": steps_de[i],
                    "step_img": base64_image,
                }
            )

        return {
            "category": tutorial_data["category"],
            "subject": tutorial_data["subject"],
            "drawing_id": tutorial_data["drawing_id"],
            "steps": tutorial_steps,
            "total_steps": len(tutorial_steps),
        }

    def list_all_subjects(self) -> List[str]:
        """Get a flat list of all available subjects"""
        subjects = []
        for category, items in self.database.items():
            subjects.extend(items.keys())
        return sorted(subjects)

    def get_random_subject(self) -> Optional[str]:
        """Get a random subject from the database"""
        all_subjects = self.list_all_subjects()
        if not all_subjects:
            return None
        return random.choice(all_subjects)

    def get_subject_info(self, subject: str) -> Optional[Dict]:
        """Get detailed information about a subject"""
        result = self.find_subject(subject)
        if not result:
            return None

        category, subject_key, subject_data = result

        # Count total drawings and steps
        total_drawings = len(subject_data)
        total_steps = 0
        for drawing_data in subject_data.values():
            total_steps += len(drawing_data.get("steps_en", []))

        return {
            "category": category,
            "subject": subject_key,
            "total_drawings": total_drawings,
            "total_steps": total_steps,
            "available_drawings": list(subject_data.keys()),
        }
