import time
import base64
import json
from io import BytesIO
from PIL import Image
from openai import OpenAI
from typing import Tuple, Dict, Any, Optional, List
from src.core.config import settings
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from src.models import Story, Drawing
from src.repositories import StoryRepository, DrawingRepository
from src.services.storage_service import StorageService
from src.core.logger import logger
from src.prompts import (
    get_story_generation_prompt,
    get_story_generation_prompt_bilingual,
)


class StoryService:
    """Service for generating children's stories from images using GPT-4 Vision"""

    def __init__(self):
        if not settings.OPENAI_API_KEY:
            raise ValueError("OpenAI API key is required for story generation")

        self.client = OpenAI(api_key=settings.OPENAI_API_KEY)
        self.model = "gpt-4o"  # GPT-4 with vision capabilities

        # Initialize storage service for downloading images from Spaces
        try:
            self.storage_service = StorageService()
            logger.info("✅ StorageService initialized for story generation")
        except Exception as e:
            logger.warning(f"⚠️ StorageService initialization failed: {e}")
            self.storage_service = None

    def generate_story(self, image_base64: str) -> Tuple[str, str, str, str, float]:
        """
        Generate a children's story from an image in both English and German.

        Args:
            image_base64: Base64 encoded image

        Returns:
            Tuple of (title_en, title_de, story_text_en, story_text_de, generation_time)
        """

        start_time = time.time()

        try:
            # Get bilingual prompt
            story_prompt = get_story_generation_prompt_bilingual()

            # Prepare the message with image
            messages = [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": story_prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/png;base64,{image_base64}"
                            },
                        },
                    ],
                }
            ]

            # Call OpenAI API
            response = self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                max_tokens=1500,  # Increased for bilingual content
                temperature=0.8,  # Creative but not too random
            )

            duration = time.time() - start_time

            if not response.choices or not response.choices[0].message.content:
                raise ValueError("Empty response from OpenAI API")

            # Parse the response as JSON
            content = response.choices[0].message.content.strip()

            try:
                # Remove markdown code blocks if present (```json ... ```)
                if content.startswith("```"):
                    # Remove opening ```json or ```
                    content = content.split("```", 1)[1]
                    if content.startswith("json"):
                        content = content[4:]
                    # Remove closing ```
                    content = content.rsplit("```", 1)[0]
                    content = content.strip()

                logger.info(
                    f" Cleaned response content (first 100 chars): {content[:100]}"
                )

                # Try to parse as JSON
                response_json = json.loads(content)
                title_en = response_json.get("title_en", "A Wonderful Adventure")
                title_de = response_json.get("title_de", "Ein wunderbares Abenteuer")
                story_text_en = response_json.get("story_text_en", "")
                story_text_de = response_json.get("story_text_de", "")

                logger.info(
                    f"✅ Successfully parsed bilingual story: EN='{title_en}', DE='{title_de}' "
                    f"(EN: {len(story_text_en)} chars, DE: {len(story_text_de)} chars)"
                )

                # Validate that both languages have content
                if not story_text_en or not story_text_de:
                    raise ValueError("Missing story content in one or both languages")

                return title_en, title_de, story_text_en, story_text_de, duration

            except json.JSONDecodeError as e:
                logger.error(f" Failed to parse JSON response: {str(e)}")
                logger.error(f"Raw response: {content[:500]}")
                raise ValueError(
                    f"AI response was not valid JSON. Please try again. Error: {str(e)}"
                )

        except Exception as e:
            duration = time.time() - start_time
            logger.error(f"❌ Story generation failed: {str(e)}")
            raise ValueError(f"Story generation failed: {str(e)}")

    def validate_image_base64(self, image_base64: str) -> bool:
        """
        Validate that the base64 string is a valid image.

        Args:
            image_base64: Base64 encoded image string

        Returns:
            True if valid image, False otherwise
        """

        try:
            # Remove data URL prefix if present
            if image_base64.startswith("data:image"):
                image_base64 = image_base64.split(",")[1]

            # Decode base64
            image_data = base64.b64decode(image_base64)

            # Try to open with PIL
            image = Image.open(BytesIO(image_data))

            # Check reasonable size
            width, height = image.size
            if width > 2048 or height > 2048 or width < 50 or height < 50:
                return False

            return True
        except Exception:
            return False

    def get_story_examples(self) -> dict:
        """
        Get example stories for different types of images.
        Useful for frontend to show users what to expect.
        """

        return {
            "animal_story": {
                "title": "Bella the Brave Little Cat",
                "preview": "Once upon a time, there was a fluffy orange cat named Bella who loved to explore...",
            },
            "nature_story": {
                "title": "The Magic Garden Adventure",
                "preview": "In a beautiful garden filled with colorful flowers, something magical was about to happen...",
            },
            "character_story": {
                "title": "The Kind Princess and Her Friends",
                "preview": "Princess Luna was the kindest princess in all the land, and she had a very special gift...",
            },
        }

    async def create_story(
        self,
        db: AsyncSession,
        image_base64: str,
        user_id: UUID,
        drawing_id: UUID = None,
        image_url: str = "",
    ) -> Dict[str, Any]:
        """
        Complete story creation flow: generate bilingual story and save to database.

        Supports two modes:
        1. Direct base64 image (image_base64 provided)
        2. Image URL from Spaces (image_url provided)

        Args:
            db: Async database session
            image_base64: Base64 encoded image (optional if image_url provided)
            user_id: UUID of the user creating the story
            drawing_id: Optional UUID of the associated drawing
            image_url: Optional URL of the image from Spaces

        Returns:
            Dictionary with story_id, title, story_text_en, story_text_de, and generation_time

        Raises:
            ValueError: If image validation fails or generation fails
        """

        # Determine which image source to use
        final_image_base64 = image_base64

        # If image_url is provided, download and convert to base64
        if image_url and not image_base64:
            logger.info(f"🔄 Re-using existing image from URL: {image_url}")

            # Validate URL and extract user_id
            if self.storage_service:
                try:
                    url_user_id = self.storage_service.validate_and_extract_user_id(
                        image_url
                    )
                    # Verify the URL belongs to the current user
                    if url_user_id != user_id:
                        raise ValueError(
                            "Image URL does not belong to the current user"
                        )
                    logger.info("✅ URL validated and belongs to current user")
                except Exception as e:
                    raise ValueError(f"Invalid image URL: {str(e)}")

            # Download image from Spaces
            if self.storage_service:
                try:
                    logger.info("📥 Downloading image from Spaces...")
                    image_bytes = self.storage_service.download_image_as_bytes(
                        image_url
                    )
                    logger.info(f"✅ Image downloaded: {len(image_bytes)} bytes")
                    # Convert to base64
                    final_image_base64 = base64.b64encode(image_bytes).decode("utf-8")
                    logger.info("✅ Image converted to base64")
                except Exception as e:
                    raise ValueError(f"Failed to download image from Spaces: {str(e)}")
            else:
                raise ValueError("Storage service not available for downloading images")

        elif not image_base64 and not image_url:
            raise ValueError("Either image_base64 or image_url must be provided")

        # Validate image
        if not self.validate_image_base64(final_image_base64):
            raise ValueError(
                "Invalid image data. Please provide a valid base64 encoded image."
            )

        # Generate bilingual story (both EN and DE in one call)
        logger.info("🎨 Generating bilingual story (EN + DE)...")
        title_en, title_de, story_text_en, story_text_de, generation_time = (
            self.generate_story(final_image_base64)
        )

        logger.info(
            f"✅ Story generated successfully: EN='{title_en}', DE='{title_de}' "
            f"(EN: {len(story_text_en)} chars, DE: {len(story_text_de)} chars)"
        )

        # Check if a story already exists for this image
        # If it does, delete it to ensure only one story per image
        if image_url and drawing_id:
            existing_story = await StoryRepository.find_by_drawing_id_and_image_url(
                db, drawing_id, image_url
            )
            if existing_story:
                logger.info(
                    f"🗑️ Deleting existing story {existing_story.id} for image {image_url}"
                )
                await Story.delete(db, existing_story.id)
                logger.info(f"✅ Existing story deleted")

        # Save story to database with both languages
        saved_story = await Story.create(
            db,
            user_id=user_id,
            drawing_id=drawing_id,
            title_en=title_en,
            title_de=title_de,
            story_text_en=story_text_en,
            story_text_de=story_text_de,
            image_url=image_url,
            generation_time_ms=int(generation_time * 1000),
        )

        logger.info(f"💾 Story saved to database with ID: {saved_story.id}")

        return {
            "story_id": str(saved_story.id),
            "title_en": title_en,
            "title_de": title_de,
            "story_text_en": story_text_en,
            "story_text_de": story_text_de,
            "generation_time": generation_time,
        }

    async def save_story_to_db(
        self,
        db: AsyncSession,
        user_id: UUID,
        title: str,
        story_text_en: str,
        story_text_de: str,
        image_url: str,
        generation_time_ms: int,
        drawing_id: UUID = None,
    ) -> Any:
        """
        Save a generated story to the database.

        Args:
            db: Async database session
            user_id: UUID of the user creating the story
            title: Story title
            story_text_en: Story text in English
            story_text_de: Story text in German
            image_url: URL of the image used for story generation
            generation_time_ms: Time taken to generate story in milliseconds
            drawing_id: Optional UUID of the associated drawing

        Returns:
            Saved Story model instance
        """

        story = await Story.create(
            db,
            user_id=user_id,
            drawing_id=drawing_id,
            title=title,
            story_text_en=story_text_en,
            story_text_de=story_text_de,
            image_url=image_url,
            generation_time_ms=generation_time_ms,
        )
        return story

    async def get_story_for_image(
        self,
        db: AsyncSession,
        drawing_id: UUID,
        image_url: str,
        user_id: UUID,
    ) -> Optional[Dict[str, Any]]:
        """
        Fetch a specific story for a drawing and image URL.

        Args:
            db: Async database session
            drawing_id: UUID of the drawing
            image_url: URL of the image
            user_id: UUID of the user (for ownership check)

        Returns:
            Story details if found, or None if not found

        Raises:
            ValueError: If drawing not found or user doesn't own it
        """

        try:
            logger.info(
                f"📖 Fetching story for drawing {drawing_id} and image {image_url}"
            )

            # Get drawing to verify ownership
            drawing = await DrawingRepository.find_by_id_with_tutorial(db, drawing_id)

            if not drawing:
                logger.warning(f"Drawing not found: {drawing_id}")
                raise ValueError("Drawing not found")

            # Check ownership
            if drawing.user_id != user_id:
                logger.warning(
                    f"Unauthorized access attempt to drawing {drawing_id} by user {user_id}"
                )
                raise ValueError("You don't have permission to access this drawing")

            # Get story for this image
            story = await StoryRepository.find_by_drawing_id_and_image_url(
                db, drawing_id, image_url
            )

            if not story:
                logger.info(
                    f"No story found for drawing {drawing_id} and image {image_url}"
                )
                return None

            logger.info(f"Retrieved story {story.id} for drawing {drawing_id}")

            return {
                "id": str(story.id),
                "title_en": story.title_en,
                "title_de": story.title_de,
                "story_text_en": story.story_text_en,
                "story_text_de": story.story_text_de,
                "image_url": story.image_url,
                "is_favorite": story.is_favorite,
                "generation_time_ms": story.generation_time_ms,
                "created_at": (
                    story.created_at.isoformat() if story.created_at else None
                ),
            }

        except ValueError:
            raise
        except Exception as e:
            logger.error(f"Failed to fetch story for image: {str(e)}")
            raise ValueError(f"Failed to fetch story for image: {str(e)}")

    async def get_all_stories_for_drawing(
        self,
        db: AsyncSession,
        drawing_id: UUID,
        user_id: UUID,
    ) -> Dict[str, Any]:
        """
        Get all stories for a drawing, organized by image URL.

        Returns stories mapped by image_url for easy frontend lookup.
        Includes stories for the original image and all edited images.

        Args:
            db: Async database session
            drawing_id: UUID of the drawing
            user_id: UUID of the user (for ownership check)

        Returns:
            Dictionary with stories organized by image_url

        Raises:
            ValueError: If drawing not found or user doesn't own it
        """

        try:
            logger.info(f"📖 Fetching all stories for drawing: {drawing_id}")

            # Get drawing to verify ownership
            drawing = await DrawingRepository.find_by_id_with_tutorial(db, drawing_id)

            if not drawing:
                logger.warning(f"Drawing not found: {drawing_id}")
                raise ValueError("Drawing not found")

            # Check ownership
            if drawing.user_id != user_id:
                logger.warning(
                    f"Unauthorized access attempt to drawing {drawing_id} by user {user_id}"
                )
                raise ValueError("You don't have permission to access this drawing")

            # Get all stories for this drawing
            stories = await StoryRepository.find_by_drawing_id(db, drawing_id)

            logger.info(f"Retrieved {len(stories)} stories for drawing {drawing_id}")

            # Organize stories by image_url
            stories_by_image = {}
            for story in stories:
                stories_by_image[story.image_url] = {
                    "id": str(story.id),
                    "title_en": story.title_en,
                    "title_de": story.title_de,
                    "story_text_en": story.story_text_en,
                    "story_text_de": story.story_text_de,
                    "image_url": story.image_url,
                    "is_favorite": story.is_favorite,
                    "generation_time_ms": story.generation_time_ms,
                    "created_at": (
                        story.created_at.isoformat() if story.created_at else None
                    ),
                }

            return {
                "success": True,
                "drawing_id": str(drawing_id),
                "stories_by_image": stories_by_image,
            }

        except ValueError:
            raise
        except Exception as e:
            logger.error(f"Failed to fetch stories for drawing: {str(e)}")
            raise ValueError(f"Failed to fetch stories for drawing: {str(e)}")
