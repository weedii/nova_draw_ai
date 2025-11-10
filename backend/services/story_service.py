import time
import base64
from io import BytesIO
from PIL import Image
from openai import OpenAI
from typing import Tuple
from config import settings


class StoryService:
    """Service for generating children's stories from images using GPT-4 Vision"""

    def __init__(self):
        if not settings.openai_api_key:
            raise ValueError("OpenAI API key is required for story generation")

        self.client = OpenAI(api_key=settings.openai_api_key)
        self.model = "gpt-4o"  # GPT-4 with vision capabilities

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
