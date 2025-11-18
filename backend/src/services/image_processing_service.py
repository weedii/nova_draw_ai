import time
import base64
import logging
from pathlib import Path
from PIL import Image
from io import BytesIO
from google import genai
from openai import OpenAI
from typing import Tuple, Any
from src.core.config import settings
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class ImageProcessingService:
    """Service for processing images using Google Gemini"""

    def __init__(self):
        logger.info("Initializing ImageProcessingService...")

        if not settings.GOOGLE_API_KEY:
            logger.error("Google API key is missing")
            raise ValueError("Google API key is required for image processing")
        if not settings.OPENAI_API_KEY:
            logger.error("OpenAI API key is missing")
            raise ValueError("OpenAI API key is required for prompt enhancement")

        self.gemini_client = genai.Client(api_key=settings.GOOGLE_API_KEY)
        self.openai_client = OpenAI(api_key=settings.OPENAI_API_KEY)
        self.gemini_model = "gemini-2.5-flash-image-preview"
        self.openai_model = "gpt-3.5-turbo"  # Cheap and fast for prompt enhancement

        logger.info(f"ImageProcessingService initialized successfully")
        logger.info(f"Using Gemini model: {self.gemini_model}")
        logger.info(f"Using OpenAI model: {self.openai_model}")

    def enhance_prompt(self, user_prompt: str) -> str:
        """
        Use GPT-3.5-turbo to enhance a simple user prompt into a detailed, professional prompt for Gemini.

        Args:
            user_prompt: Simple user request (e.g., "make it alive")

        Returns:
            Enhanced, detailed prompt for better Gemini results
        """
        logger.info(f"🔄 Starting prompt enhancement for: '{user_prompt}'")
        enhancement_start = time.time()

        try:
            enhancement_prompt = f"""
            You are an EXPERT creative director for a magical children's art app (ages 4-8). Your job is to transform simple requests into INCREDIBLY DETAILED, VIVID, and IMAGINATIVE prompts that will blow kids' minds with amazing visual transformations!

            The child's request: "{user_prompt}"

            ⚠️ IMPORTANT - UNDERSTAND CHILD LANGUAGE VARIATIONS:
            Kids use imperfect grammar and different words to express the same idea. Treat these as IDENTICAL:
            - "put in paris" = "make on paris" = "place in paris" = "put to paris" = "make in paris"
            - "make it alive" = "make this alive" = "bring to life" = "make living"
            - "add colors" = "make colorful" = "put colors" = "color this"
            - "make big" = "make bigger" = "make this big"
            
            Focus on the INTENT, not the exact words. Ignore grammar mistakes with prepositions (in/on/to/at).

            CREATE AN ULTRA-DETAILED, CREATIVE PROMPT that will produce STUNNING, MAGICAL results!

            🎨 CREATIVE ENHANCEMENT RULES:
            
            1. BE WILDLY IMAGINATIVE & SPECIFIC:
               - Don't just say "add sparkles" - describe "thousands of tiny rainbow sparkles that swirl and dance around like fireflies, leaving trails of glittering stardust"
               - Don't just say "bright colors" - specify "vibrant neon pink, electric blue, sunshine yellow, and lime green that glow and pulse with energy"
               - Add unexpected, delightful details that surprise and amaze
               - Think like a Pixar or Disney artist - every detail matters!
            
            2. LAYER MULTIPLE EFFECTS:
               - Combine 4-6 different visual elements
               - Add depth: foreground effects, mid-ground transformations, background magic
               - Include lighting effects (glows, shimmers, rays of light)
               - Add motion suggestions (swirling, floating, dancing, sparkling)
               - Include atmospheric effects (magical mist, glowing particles, energy waves)
            
            3. USE POWERFUL, DESCRIPTIVE LANGUAGE:
               - Instead of "nice" use: dazzling, mesmerizing, enchanting, breathtaking
               - Instead of "pretty" use: stunning, gorgeous, spectacular, magnificent
               - Instead of "colorful" use: vibrant, luminous, radiant, iridescent
               - Paint a picture with words!
            
            4. MAKE IT FEEL ALIVE & DYNAMIC:
               - Suggest movement and energy
               - Add emotional elements (joyful, playful, friendly, excited)
               - Create a sense of magic happening right now
               - Make it feel interactive and responsive
            
            5. ALWAYS KEEP IT KID-SAFE:
               - Only happy, positive, uplifting content
               - Friendly, cute, and welcoming vibes
               - No scary, dark, or frightening elements
               - Cartoon/animated style, never realistic in a scary way
            
            📚 ULTRA-CREATIVE EXAMPLES (showing how to interpret child language):
            
            Child says: "put this house in paris" OR "make this house on paris" (SAME INTENT!)
            → Enhanced: "Transport this into the heart of MAGICAL PARIS! Place the subject on a charming cobblestone street with the magnificent Eiffel Tower rising majestically in the background, its iron lattice structure gleaming in golden sunset light. Add a dreamy Parisian atmosphere with soft pink and lavender clouds floating in the sky. Include classic French elements: colorful flower boxes overflowing with red geraniums and purple petunias on wrought-iron balconies, a quaint café with striped awnings and small round tables, vintage lampposts with warm glowing lights, and a romantic bridge over the Seine River in the distance. Scatter rose petals gently floating through the air. Add the Arc de Triomphe visible on the horizon. Include a cheerful French bakery with a red-and-white striped awning displaying fresh croissants and baguettes in the window. Paint the sky in beautiful sunset hues of peach, coral, and soft purple. Add twinkling fairy lights strung between buildings. Include a friendly artist with an easel painting the scene. Make the Eiffel Tower sparkle with thousands of golden lights. Add fluffy white clouds shaped like hearts drifting by. The entire scene should feel like stepping into a magical storybook version of Paris - romantic, charming, and absolutely enchanting!"
            
            Child says: "make it alive" OR "bring to life" (SAME INTENT!)
            → Enhanced: "Transform this into a LIVING, BREATHING character with enormous sparkling eyes that gleam with curiosity and joy, with bright highlights and twinkling star reflections dancing inside them. Add a huge delighted smile showing pure happiness, rosy pink cheeks that glow warmly, and expressive eyebrows that show emotion. Surround it with swirling magical energy - ribbons of shimmering turquoise and golden light that spiral around like living aurora borealis. Add floating heart-shaped sparkles, tiny glowing orbs of rainbow light that orbit around it, and a subtle aura of radiant energy. Make the colors more vibrant and saturated - like they're glowing from within. Add gentle motion blur to suggest it's alive and moving, with strands of hair or edges that seem to flutter in a magical breeze. Include particle effects of stardust that trail behind any movement, creating a sense of magic and life force. The overall effect should be like a beloved Pixar character coming to life before your eyes!"
            
            Child says: "add colors" OR "make colorful" (SAME INTENT!)
            → Enhanced: "EXPLODE this image with an INSANE rainbow of colors! Transform it into a psychedelic wonderland where every pixel bursts with vibrant, saturated hues. Start with a gradient background that transitions through all rainbow colors - hot pink melting into electric purple, flowing into sky blue, merging with lime green, blazing into sunshine yellow, and burning into fiery orange. Overlay the main subject with iridescent color shifts that shimmer and change like oil on water or butterfly wings. Add floating, translucent butterflies in neon colors that seem to glow from within. Scatter thousands of tiny colorful sparkles - each one a different color of the rainbow, twinkling and pulsing with light. Paint rainbow beams shooting out from behind the subject like cosmic rays. Include colorful paint splashes and drips that look like liquid light. Add holographic effects that shimmer with rainbow reflections. Make flowers burst into bloom with petals of every color imaginable. Include glowing particles of colored light floating through the air like fireflies. Add chromatic aberration effects around edges for that dreamy, magical look. The result should look like a rainbow exploded in the most beautiful way possible - like stepping into a magical world made entirely of living color!"

            💡 YOUR TURN: Now transform "{user_prompt}" into an INCREDIBLY DETAILED, WILDLY CREATIVE prompt that will create absolutely STUNNING results! Use at least 150-250 words. Be specific, be imaginative, be AMAZING!
            
            REMEMBER: Interpret the child's INTENT first (ignore grammar mistakes), then create your magical enhancement based on what they really mean!

            Return ONLY your enhanced creative prompt - no labels, no explanations, just pure creative magic!
            """

            logger.info(f"📤 Sending enhancement request to {self.openai_model}")

            response = self.openai_client.chat.completions.create(
                model=self.openai_model,
                messages=[{"role": "user", "content": enhancement_prompt}],
                max_tokens=500,  # More tokens for detailed creative descriptions
                temperature=0.9,  # Higher creativity for more imaginative results
            )

            enhancement_time = time.time() - enhancement_start
            logger.info(f"⚡ GPT enhancement completed in {enhancement_time:.2f}s")

            if not response.choices or not response.choices[0].message.content:
                logger.warning(
                    "⚠️ Empty response from OpenAI API, using original prompt"
                )
                return user_prompt

            enhanced_prompt = response.choices[0].message.content.strip()

            # Log the enhancement results
            logger.info(f"✅ Prompt enhancement successful!")
            logger.info(f"📝 Original: '{user_prompt}'")
            logger.info(
                f"🚀 Enhanced (preview): '{enhanced_prompt[:100]}{'...' if len(enhanced_prompt) > 100 else ''}'"
            )
            logger.info(
                f"📊 Enhancement ratio: {len(enhanced_prompt)}/{len(user_prompt)} characters"
            )

            # Log the full enhanced prompt for debugging
            logger.info("=" * 50)
            logger.info("🎯 FULL ENHANCED PROMPT FOR GEMINI:")
            logger.info(f"'{enhanced_prompt}'")
            logger.info("=" * 50)

            return enhanced_prompt

        except Exception as e:
            enhancement_time = time.time() - enhancement_start
            logger.error(
                f"❌ Prompt enhancement failed after {enhancement_time:.2f}s: {e}"
            )
            logger.info(f"🔄 Falling back to original prompt: '{user_prompt}'")
            return user_prompt

    def process_image(self, image_data: bytes, prompt: str) -> Tuple[str, float]:
        """
        Process an image with a text prompt using Gemini.

        Args:
            image_data: Raw image bytes
            prompt: Text prompt for processing (e.g., "make it alive")

        Returns:
            Tuple of (base64_result_image, processing_time)
        """
        logger.info(f"🎨 Starting image processing with prompt: '{prompt}'")
        start_time = time.time()

        try:
            # Convert bytes to PIL Image
            logger.info("📷 Processing uploaded image...")
            input_image = Image.open(BytesIO(image_data))
            original_size = input_image.size
            original_mode = input_image.mode

            logger.info(
                f"📊 Image info: {original_size[0]}x{original_size[1]} pixels, mode: {original_mode}"
            )

            # Ensure image is in RGB mode
            if input_image.mode != "RGB":
                logger.info(f"🔄 Converting image from {input_image.mode} to RGB")
                input_image = input_image.convert("RGB")

            # Step 1: Enhance the user's simple prompt using GPT-3.5-turbo
            logger.info("🚀 Step 1: Enhancing user prompt with GPT-3.5-turbo...")
            enhanced_prompt = self.enhance_prompt(prompt)

            # Step 2: Create the final prompt for Gemini using the enhanced version
            logger.info("🎯 Step 2: Preparing final prompt for Gemini...")
            full_prompt = f"""
            You are a MASTER digital artist and visual effects wizard working for a premium children's creativity app. Your transformations must be SPECTACULAR, MAGICAL, and absolutely BREATHTAKING!
            
            🎨 TRANSFORMATION MISSION:
            {enhanced_prompt}
            
            🚀 EXECUTION GUIDELINES:
            
            1. MAKE IT BOLD & DRAMATIC:
               - Create changes that are IMMEDIATELY OBVIOUS and WOW-WORTHY
               - Don't be subtle - kids love BIG, IMPRESSIVE transformations
               - Push the visual effects to the MAX while staying beautiful
               - Make it look like professional movie-quality VFX
            
            2. PRESERVE THE CORE:
               - Keep the main subject recognizable
               - Transform it dramatically but don't lose its identity
               - Enhance what's there, don't replace it completely
            
            3. VISUAL EXCELLENCE:
               - Use cinema-quality rendering and effects
               - Make colors vibrant, saturated, and eye-catching
               - Add depth with layers, lighting, and atmospheric effects
               - Create a polished, professional final result
               - Ensure everything is sharp, clear, and high-quality
            
            4. MAGICAL ATMOSPHERE:
               - Add that "Disney/Pixar magic" feeling
               - Make it feel alive and full of wonder
               - Create a sense of movement and energy
               - Infuse every pixel with creativity and joy
            
            5. TECHNICAL PERFECTION:
               - Return ONLY the transformed image
               - No text, watermarks, signatures, or labels
               - Maintain proper resolution and quality
               - Ensure smooth blending of all effects
            
            🌟 CREATE PURE MAGIC! Transform this image into something INCREDIBLE that will make kids gasp with delight!
            """

            # Prepare content for Gemini
            contents = [full_prompt, input_image]

            logger.info(f"📤 Sending image processing request to {self.gemini_model}")
            gemini_start = time.time()

            # Call Gemini API
            response = self.gemini_client.models.generate_content(
                model=self.gemini_model,
                contents=contents,
            )

            gemini_time = time.time() - gemini_start
            logger.info(f"⚡ Gemini processing completed in {gemini_time:.2f}s")

            duration = time.time() - start_time

            # Extract and process the result image
            logger.info("🔍 Extracting result image from Gemini response...")
            for part in response.candidates[0].content.parts:
                if part.inline_data is not None:
                    try:
                        # Get the raw image data
                        result_image_data = part.inline_data.data
                        logger.info(
                            f"📦 Received image data: {len(result_image_data)} bytes"
                        )

                        # Handle different data formats
                        if isinstance(
                            result_image_data, bytes
                        ) and result_image_data.startswith(b"\x89PNG"):
                            # Already binary PNG data
                            logger.info("✅ Image data is already in binary PNG format")
                            processed_data = result_image_data
                        else:
                            # Try base64 decoding
                            logger.info("🔄 Attempting base64 decoding...")
                            try:
                                processed_data = base64.b64decode(result_image_data)
                                if not processed_data.startswith(b"\x89PNG"):
                                    # If not PNG after decoding, use original
                                    logger.warning(
                                        "⚠️ Decoded data is not PNG, using original"
                                    )
                                    processed_data = result_image_data
                                else:
                                    logger.info("✅ Successfully decoded base64 to PNG")
                            except Exception as decode_error:
                                logger.warning(
                                    f"⚠️ Base64 decode failed: {decode_error}, using original data"
                                )
                                processed_data = result_image_data

                        # Convert to PIL Image and then to base64
                        logger.info("🖼️ Converting to PIL Image...")
                        result_image = Image.open(BytesIO(processed_data))
                        result_size = result_image.size
                        result_mode = result_image.mode

                        logger.info(
                            f"📊 Result image: {result_size[0]}x{result_size[1]} pixels, mode: {result_mode}"
                        )

                        # Convert to RGB if necessary
                        if result_image.mode != "RGB":
                            logger.info(
                                f"🔄 Converting result from {result_image.mode} to RGB"
                            )
                            result_image = result_image.convert("RGB")

                        # Convert to base64 for response
                        logger.info("📤 Converting to base64 for response...")
                        buffered = BytesIO()
                        result_image.save(buffered, format="PNG")
                        img_base64 = base64.b64encode(buffered.getvalue()).decode(
                            "utf-8"
                        )

                        base64_size = len(img_base64)
                        logger.info(
                            f"✅ Base64 conversion complete: {base64_size} characters"
                        )
                        logger.info(
                            f"🎉 Image processing successful! Total time: {duration:.2f}s"
                        )

                        return img_base64, duration

                    except Exception as img_error:
                        logger.error(f"❌ Failed to process result image: {img_error}")
                        raise ValueError(f"Failed to process result image: {img_error}")

            logger.error("❌ No image data received in Gemini response")
            raise ValueError("No image data received in response")

        except Exception as e:
            duration = time.time() - start_time
            logger.error(f"❌ Image processing failed after {duration:.2f}s: {str(e)}")
            raise ValueError(f"Image processing failed: {str(e)}")

    def validate_image(self, image_data: bytes) -> bool:
        """
        Validate that the uploaded data is a valid image.

        Args:
            image_data: Raw image bytes

        Returns:
            True if valid image, False otherwise
        """
        try:
            image = Image.open(BytesIO(image_data))
            # Check if it's a reasonable size (not too large)
            width, height = image.size
            if width > 2048 or height > 2048:
                return False
            return True
        except Exception:
            return False

    def get_image_info(self, image_data: bytes) -> dict:
        """
        Get information about the uploaded image.

        Args:
            image_data: Raw image bytes

        Returns:
            Dictionary with image information
        """
        try:
            image = Image.open(BytesIO(image_data))
            return {
                "width": image.size[0],
                "height": image.size[1],
                "mode": image.mode,
                "format": image.format,
                "size_bytes": len(image_data),
            }
        except Exception as e:
            logger.error(f"Failed to get image info: {e}")
            return {}

    async def save_drawing_to_db(
        self,
        db: AsyncSession,
        user_id: UUID,
        result_base64: str,
        tutorial_id: UUID = None,
    ) -> Any:
        """
        Save a processed drawing to the database.

        Args:
            db: Async database session
            user_id: UUID of the user who edited the image
            result_base64: Base64 encoded processed image
            tutorial_id: Optional UUID of the associated tutorial

        Returns:
            Saved Drawing model instance
        """
        from models import Drawing

        drawing = await Drawing.create(
            db,
            user_id=user_id,
            tutorial_id=tutorial_id,
            uploaded_image_url="",
            edited_images_urls=[result_base64],
        )
        return drawing
