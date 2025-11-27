import time
import base64
from io import BytesIO
from PIL import Image
from openai import OpenAI
from typing import Tuple, Dict, Any
from src.core.config import settings
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from src.models import Story
from src.services.storage_service import StorageService
from src.core.logger import logger


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

    def generate_story(
        self, image_base64: str, language: str = "en"
    ) -> Tuple[str, str, float]:
        """
        Generate a children's story from an image.

        Args:
            image_base64: Base64 encoded image
            language: Language for story generation ('en' or 'de')

        Returns:
            Tuple of (story_title, story_text, generation_time)
        """
        start_time = time.time()

        try:
            # Create the prompt based on language
            if language == "de":
                story_prompt = """
                Du bist ein professioneller Kinderbuchautor, der fesselnde, lehrreiche und altersgerechte Geschichten für Kinder im Alter von 4-7 Jahren erstellt.
                
                Schau dir dieses Bild an und erstelle eine wunderbare kurze Geschichte basierend auf dem, was du siehst.
                
                GESCHICHTENANFORDERUNGEN:
                - Zielgruppe: 4-7 Jahre alte Kinder
                - Länge: 150-250 Wörter (perfekt für Schlafenszeit oder Lesezeit)
                - Sprache: Einfacher, klarer Wortschatz, den junge Kinder verstehen können
                - Ton: Positiv, ermutigend und magisch
                - Enthalten: Ein klarer Anfang, Mittelteil und Ende
                - Themen: Freundschaft, Freundlichkeit, Abenteuer, Lernen oder Entdeckung
                - Mache es spannend und Spaß beim Vorlesen
                
                GESCHICHTENSTRUKTUR:
                1. Beginne mit einer interessanten Figur oder Situation aus dem Bild
                2. Erstelle ein einfaches Problem oder Abenteuer
                3. Zeige, wie die Figur es löst oder etwas lernt
                4. Ende mit einer positiven, erhebenden Schlussfolgerung
                
                SCHREIBSTIL:
                - Verwende kurze, einfache Sätze
                - Füge einige Dialoge hinzu, um es lebendig zu machen
                - Füge beschreibende Wörter hinzu, die Kindern helfen zu visualisieren
                - Mache es rhythmisch und angenehm zum Vorlesen
                - Vermeide gruselige oder negative Themen
                
                Bitte gib an:
                1. Einen einprägsamen Titel (5-8 Wörter)
                2. Die vollständige Geschichte
                
                Formatiere deine Antwort wie folgt:
                TITEL: [Dein Titel hier]
                
                GESCHICHTE:
                [Deine Geschichte hier]
                """
            else:
                story_prompt = """
                You are a professional children's story writer who creates engaging, educational, and age-appropriate stories for children aged 4-7 years old.
                
                Look at this image and create a wonderful short story based on what you see.
                
                STORY REQUIREMENTS:
                - Target audience: 4-7 year old children
                - Length: 150-250 words (perfect for bedtime or reading time)
                - Language: Simple, clear vocabulary that young children can understand
                - Tone: Positive, encouraging, and magical
                - Include: A clear beginning, middle, and end
                - Themes: Friendship, kindness, adventure, learning, or discovery
                - Make it engaging and fun to read aloud
                
                STORY STRUCTURE:
                1. Start with an interesting character or situation from the image
                2. Create a simple problem or adventure
                3. Show how the character solves it or learns something
                4. End with a positive, uplifting conclusion
                
                WRITING STYLE:
                - Use short, simple sentences
                - Include some dialogue to make it lively
                - Add descriptive words that help children visualize
                - Make it rhythmic and pleasant to read aloud
                - Avoid scary or negative themes
                
                Please provide:
                1. A catchy title (5-8 words)
                2. The complete story
                
                Format your response as:
                TITLE: [Your title here]
                
                STORY:
                [Your story here]
                """

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
                max_tokens=500,
                temperature=0.8,  # Creative but not too random
            )

            duration = time.time() - start_time

            if not response.choices or not response.choices[0].message.content:
                raise ValueError("Empty response from OpenAI API")

            # Parse the response
            content = response.choices[0].message.content.strip()

            # Extract title and story
            lines = content.split("\n")
            title = ""
            story = ""

            # Find title (support both English "TITLE:" and German "TITEL:")
            for line in lines:
                if line.startswith("TITLE:") or line.startswith("TITEL:"):
                    title = line.replace("TITLE:", "").replace("TITEL:", "").strip()
                    break

            # Find story (support both English "STORY:" and German "GESCHICHTE:")
            story_started = False
            story_lines = []
            for line in lines:
                if line.startswith("STORY:") or line.startswith("GESCHICHTE:"):
                    story_started = True
                    continue
                if story_started:
                    story_lines.append(line)

            story = "\n".join(story_lines).strip()

            # Fallback if parsing fails
            if not title:
                title = (
                    "A Wonderful Adventure"
                    if language == "en"
                    else "Ein wunderbares Abenteuer"
                )
            if not story:
                story = content  # Use full content as story

            return title, story, duration

        except Exception as e:
            duration = time.time() - start_time
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
        language: str,
        user_id: UUID,
        drawing_id: UUID = None,
        image_url: str = "",
    ) -> Dict[str, Any]:
        """
        Complete story creation flow: generate and save to database.

        Supports two modes:
        1. Direct base64 image (image_base64 provided)
        2. Image URL from Spaces (image_url provided)

        Args:
            db: Async database session
            image_base64: Base64 encoded image (optional if image_url provided)
            language: Language for story generation ('en' or 'de')
            user_id: UUID of the user creating the story
            drawing_id: Optional UUID of the associated drawing
            image_url: Optional URL of the image from Spaces

        Returns:
            Dictionary with story_id, title, story, and generation_time

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

        # Validate language
        if language not in ["en", "de"]:
            raise ValueError("Invalid language. Please provide 'en' or 'de'.")

        # Generate story
        title, story, generation_time = self.generate_story(
            final_image_base64, language
        )

        # Prepare story data for database
        story_text_en = story if language == "en" else ""
        story_text_de = story if language == "de" else ""

        # Save story to database
        saved_story = await Story.create(
            db,
            user_id=user_id,
            drawing_id=drawing_id,
            title=title,
            story_text_en=story_text_en,
            story_text_de=story_text_de,
            image_url=image_url,
            generation_time_ms=int(generation_time * 1000),
        )

        return {
            "story_id": str(saved_story.id),
            "title": title,
            "story": story,
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
