import re
import time
from openai import OpenAI
from typing import List, Any
from src.core.config import settings
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from src.models import Drawing
from src.prompts import (
    get_drawing_steps_generation_prompt,
    get_german_translation_prompt,
)


class DrawingService:
    """Service for generating drawing steps using OpenAI GPT-4o-mini"""

    def __init__(self):
        self.client = OpenAI(api_key=settings.OPENAI_API_KEY)
        self.model = "gpt-4o-mini"

    def generate_steps(self, subject: str) -> tuple[List[str], List[str], float]:
        """
        Generate step-by-step drawing instructions for a given subject in English and German.
        Returns (english_steps, german_steps, generation_time)
        """

        # Get prompt from centralized prompt module
        prompt = get_drawing_steps_generation_prompt(subject)

        start_time = time.time()

        response = self.client.chat.completions.create(
            model=self.model, messages=[{"role": "user", "content": prompt}]
        )

        duration = time.time() - start_time

        if not response.choices or not response.choices[0].message.content:
            raise ValueError("Empty response from OpenAI API")

        steps_text = response.choices[0].message.content.strip()

        # Split by lines and clean up
        steps = [line.strip() for line in steps_text.split("\n") if line.strip()]

        # Filter out any remaining numbered lines, intro/outro text
        clean_steps = []
        for step in steps:
            # Skip lines that look like introductions or conclusions
            if any(
                phrase in step.lower()
                for phrase in [
                    "here are",
                    "steps to",
                    "have fun",
                    "enjoy",
                    "let's",
                    "now you",
                ]
            ):
                continue

            # Remove numbering if present
            clean_step = re.sub(r"^\d+\.\s*", "", step)
            if clean_step and len(clean_step) > 10:  # Ensure it's a meaningful step
                clean_steps.append(clean_step)

        if not clean_steps:
            raise ValueError("No valid steps generated")

        # Ensure we have at least min_steps, max max_steps
        if len(clean_steps) < settings.min_steps:
            raise ValueError(
                f"Generated only {len(clean_steps)} steps, but need at least {settings.min_steps}"
            )
        elif len(clean_steps) > settings.max_steps:
            clean_steps = clean_steps[: settings.max_steps]

        # Generate German translation
        german_steps = self._translate_to_german(clean_steps)

        return clean_steps, german_steps, duration

    def _translate_to_german(self, english_steps: List[str]) -> List[str]:
        """
        Translate English drawing steps to German using GPT-4o-mini.
        """
        steps_text = "\n".join(
            [f"{i+1}. {step}" for i, step in enumerate(english_steps)]
        )

        # Get prompt from centralized prompt module
        prompt = get_german_translation_prompt(steps_text)

        response = self.client.chat.completions.create(
            model=self.model, messages=[{"role": "user", "content": prompt}]
        )

        if not response.choices or not response.choices[0].message.content:
            # Fallback: return English steps if translation fails
            return english_steps

        german_text = response.choices[0].message.content.strip()
        german_steps = [
            line.strip() for line in german_text.split("\n") if line.strip()
        ]

        # Remove numbering if present
        clean_german_steps = []
        for step in german_steps:
            clean_step = re.sub(r"^\d+\.\s*", "", step)
            if clean_step:
                clean_german_steps.append(clean_step)

        # Ensure we have the same number of steps
        if len(clean_german_steps) != len(english_steps):
            return english_steps  # Fallback to English if counts don't match

        return clean_german_steps

    async def save_drawing_to_db(
        self,
        db: AsyncSession,
        user_id: UUID,
        subject: str,
        english_steps: List[str],
        german_steps: List[str],
        tutorial_id: UUID = None,
    ) -> Any:
        """
        Save generated drawing steps to the database.

        Args:
            db: Async database session
            user_id: UUID of the user creating the drawing
            subject: Subject of the drawing
            english_steps: List of drawing steps in English
            german_steps: List of drawing steps in German
            tutorial_id: Optional UUID of the associated tutorial

        Returns:
            Saved Drawing model instance
        """

        drawing = await Drawing.create(
            db,
            user_id=user_id,
            tutorial_id=tutorial_id,
            uploaded_image_url="",
            edited_images_urls=[],
        )
        return drawing
