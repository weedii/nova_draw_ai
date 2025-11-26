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
from sqlalchemy.orm import attributes
from uuid import UUID
from src.models import Drawing
from src.services.storage_service import StorageService
from src.models import Drawing, Tutorial

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

        # Initialize storage service for DigitalOcean Spaces
        try:
            self.storage_service = StorageService()
            logger.info("✅ StorageService initialized")
        except Exception as e:
            logger.warning(f"⚠️ StorageService initialization failed: {e}")
            self.storage_service = None

        logger.info(f"ImageProcessingService initialized successfully")
        logger.info(f"Using Gemini model: {self.gemini_model}")
        logger.info(f"Using OpenAI model: {self.openai_model}")

    def enhance_voice_prompt(self, user_request: str, subject: str = None) -> str:
        """
        Use GPT-3.5-turbo to create a focused prompt from voice input.
        
        This is simpler than the old enhance_prompt - it creates short, 
        preservation-focused prompts that won't lose the drawing's identity.

        Args:
            user_request: Transcribed voice request (e.g., "put it in Paris")
            subject: What the child drew (e.g., "dog", "cat") - from tutorial

        Returns:
            Short, focused prompt for Gemini
        """
        logger.info(f"🎤 Enhancing voice prompt: '{user_request}' (subject: {subject})")
        enhancement_start = time.time()

        try:
            # Build context about what was drawn
            subject_context = f"a {subject}" if subject else "their picture"
            
            enhancement_prompt = f"""A child just drew {subject_context} and said: "{user_request}"

Generate a SHORT prompt (2-3 sentences max) for an image editing AI.

RULES:
- The child's original drawing must stay recognizable
- Don't change the main shape, lines, or proportions  
- Only add or enhance what the child asked for
- Keep it kid-friendly and fun
- Add vibrant colors if needed
- Understand child language: "put in paris" = "place in Paris", "make alive" = "bring to life"

IMPORTANT: Output ONLY the prompt text. Do NOT include any prefix like "Child drew X, said Y →". Just the actual editing instructions.

GOOD OUTPUT EXAMPLES:
"Add a colorful Parisian background with the Eiffel Tower behind this child's dog drawing. Keep the dog's shape but add warm brown and golden fur colors. Add sunset sky colors."

"Transform this child's cat drawing with beautiful rainbow colors flowing through the fur. Keep the cat's shape and lines intact. Make it bright and cheerful."

"Add sparkles and a soft magical glow around this child's flower drawing. Color the petals in vibrant pinks and purples. Add some floating golden stars."
"""

            response = self.openai_client.chat.completions.create(
                model=self.openai_model,
                messages=[{"role": "user", "content": enhancement_prompt}],
                max_tokens=150,  # Short output
                temperature=0.6,  # More controlled
            )

            enhancement_time = time.time() - enhancement_start
            logger.info(f"⚡ Voice prompt enhancement completed in {enhancement_time:.2f}s")

            if not response.choices or not response.choices[0].message.content:
                logger.warning("⚠️ Empty response from OpenAI, using original")
                return user_request

            enhanced = response.choices[0].message.content.strip()
            logger.info(f"✅ Enhanced voice prompt: '{enhanced}'")
            return enhanced

        except Exception as e:
            logger.error(f"❌ Voice prompt enhancement failed: {e}")
            return user_request

    def process_image(self, image_data: bytes, prompt: str) -> Tuple[str, float]:
        """
        Process an image with a text prompt using Gemini.
        
        For predefined edit options, the prompt already contains detailed instructions
        from the database, so we skip GPT enhancement and send directly to Gemini.

        Args:
            image_data: Raw image bytes
            prompt: Text prompt for processing (detailed prompt from edit_options table)

        Returns:
            Tuple of (base64_result_image, processing_time)
        """
        logger.info(f"🎨 Starting image processing with prompt: '{prompt[:100]}...'")
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

            # Create the final prompt for Gemini
            # The prompt from edit_options already contains detailed instructions,
            # so we just wrap it with preservation guidelines
            logger.info("🎯 Preparing prompt for Gemini (no GPT enhancement)...")
            full_prompt = f"""
You are editing a child's hand-drawn picture for a kids' creativity app.

CRITICAL RULES:
1. PRESERVE THE ORIGINAL DRAWING - Keep the child's original lines, shapes, and proportions intact
2. DO NOT redraw or replace the main subject - only enhance/add to it
3. The child's drawing style must remain recognizable
4. Keep it kid-friendly, fun, and magical

YOUR TASK:
{prompt}

TECHNICAL REQUIREMENTS:
- Return ONLY the edited image
- No text, watermarks, or labels
- Maintain image quality
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

    async def edit_image_with_prompt(
        self,
        db: AsyncSession,
        prompt: str,
        user_id: UUID,
        tutorial_id: UUID = None,
        drawing_id: UUID = None,
        image_data: bytes = None,
        image_url: str = None,
    ) -> dict:
        """
        Complete image editing flow: validate, process, and save to database and Spaces.
        Supports both file upload and existing image URL from Spaces.
        If drawing_id is provided, appends the edited image to the existing drawing's edited_images_urls.

        Args:
            db: Async database session
            prompt: Processing instruction
            user_id: UUID of the user editing the image
            tutorial_id: Optional UUID of the associated tutorial
            drawing_id: Optional UUID of existing drawing to append edit to
            image_data: Raw image bytes (for new uploads)
            image_url: URL of existing image from Spaces (for re-editing)

        Returns:
            Dictionary with drawing_id, original_image_url, edited_image_url, and processing_time

        Raises:
            ValueError: If image validation fails or processing fails
        """

        # Validate that either image_data or image_url is provided
        if not image_data and not image_url:
            raise ValueError("Either image_data or image_url must be provided")

        original_image_url = None

        # Step 1: Handle image source (file upload or existing URL)
        if image_url:
            # Re-editing: Use existing image from Spaces
            logger.info(f"🔄 Re-editing existing image from URL: {image_url}")

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
                    image_data = self.storage_service.download_image_as_bytes(image_url)
                    logger.info(f"✅ Image downloaded: {len(image_data)} bytes")
                    original_image_url = image_url  # Reuse existing URL
                except Exception as e:
                    raise ValueError(f"Failed to download image from Spaces: {str(e)}")
        else:
            # New upload: Upload original image to Spaces
            logger.info("📤 Processing new image upload...")

            # Validate image
            if not self.validate_image(image_data):
                raise ValueError("Invalid image or image too large (max 2048x2048)")

            # Upload original image to Spaces
            if self.storage_service:
                try:
                    logger.info("📤 Uploading original image to Spaces...")
                    original_image_url = self.storage_service.upload_image_from_bytes(
                        image_data, user_id, image_type="original"
                    )
                    logger.info(f"✅ Original image uploaded: {original_image_url}")
                except Exception as e:
                    logger.warning(f"⚠️ Failed to upload original image: {e}")
                    # Continue without storing original URL

        # Get image info for logging
        image_info = self.get_image_info(image_data)
        logger.info(f"Processing image: {image_info}")

        # Step 2: Process the image
        result_base64, processing_time = self.process_image(image_data, prompt)

        # Step 3: Upload edited image to Spaces
        edited_image_url = None
        if self.storage_service:
            try:
                logger.info("📤 Uploading edited image to Spaces...")
                edited_image_url = self.storage_service.upload_image_from_base64(
                    result_base64, user_id, image_type="edited"
                )
                logger.info(f"✅ Edited image uploaded: {edited_image_url}")
            except Exception as e:
                logger.warning(f"⚠️ Failed to upload edited image: {e}")
                # Continue with base64 as fallback

        # Step 4: Save drawing to database with URLs
        if drawing_id:
            # Re-editing: Fetch existing drawing and append to edited_images_urls
            logger.info(f"📝 Appending edit to existing drawing: {drawing_id}")

            try:
                # Fetch the existing drawing
                existing_drawing = await Drawing.get_by_id(db, drawing_id)

                if not existing_drawing:
                    raise ValueError(f"Drawing with ID {drawing_id} not found")

                # Verify the drawing belongs to the current user
                if existing_drawing.user_id != user_id:
                    raise ValueError("Drawing does not belong to the current user")

                # Get current edited_images_urls or initialize as empty list
                current_edits = existing_drawing.edited_images_urls or []

                # Append the new edited image URL
                new_edited_url = edited_image_url if edited_image_url else result_base64
                current_edits.append(new_edited_url)

                # Mark array as modified for PostgreSQL before updating
                attributes.flag_modified(existing_drawing, "edited_images_urls")

                # Update the drawing using the update method
                saved_drawing = await Drawing.update(
                    db, drawing_id, {"edited_images_urls": current_edits}
                )

                logger.info(
                    f"✅ Edit appended to drawing. Total edits: {len(current_edits)}"
                )

            except Exception as e:
                logger.error(f"❌ Failed to append edit to existing drawing: {str(e)}")
                raise ValueError(f"Failed to append edit to drawing: {str(e)}")
        else:
            # New drawing: Create a new entry
            logger.info("📝 Creating new drawing entry")
            saved_drawing = await Drawing.create(
                db,
                user_id=user_id,
                tutorial_id=tutorial_id,
                uploaded_image_url=original_image_url,
                edited_images_urls=(
                    [edited_image_url] if edited_image_url else [result_base64]
                ),
            )

        return {
            "drawing_id": str(saved_drawing.id),
            "original_image_url": original_image_url,
            "edited_image_url": edited_image_url,
            "processing_time": processing_time,
        }

    async def edit_image_with_audio(
        self,
        db: AsyncSession,
        audio_data: bytes,
        audio_filename: str,
        language: str,
        user_id: UUID,
        tutorial_id: UUID = None,
        drawing_id: UUID = None,
        audio_service=None,
        image_data: bytes = None,
        image_url: str = None,
    ) -> dict:
        """
        Complete image editing flow with audio: transcribe, process, and save to database and Spaces.
        Supports both file upload and existing image URL from Spaces.
        If drawing_id is provided, appends the edited image to the existing drawing's edited_images_urls.

        Args:
            db: Async database session
            audio_data: Raw audio bytes
            audio_filename: Audio file name
            language: Language code ('en' or 'de')
            user_id: UUID of the user editing the image
            tutorial_id: Optional UUID of the associated tutorial
            drawing_id: Optional UUID of existing drawing to append edit to
            audio_service: AudioService instance for transcription
            image_data: Raw image bytes (for new uploads)
            image_url: URL of existing image from Spaces (for re-editing)

        Returns:
            Dictionary with drawing_id, original_image_url, edited_image_url, prompt, and processing_time

        Raises:
            ValueError: If validation or processing fails
        """

        # Validate that either image_data or image_url is provided
        if not image_data and not image_url:
            raise ValueError("Either image_data or image_url must be provided")

        # Validate language
        if language not in ["en", "de"]:
            raise ValueError("Invalid language. Please provide 'en' or 'de'.")

        # Validate audio
        if not audio_service:
            raise ValueError("Audio service not available")

        if not audio_service.validate_audio_file(
            audio_data, f"audio/{audio_filename.split('.')[-1]}"
        ):
            supported = audio_service.get_supported_formats()
            raise ValueError(
                f"Invalid audio file. Supported formats: {', '.join(supported['formats'])}. Max size: {supported['max_size_mb']}MB"
            )

        original_image_url = None

        # Step 1: Handle image source (file upload or existing URL)
        if image_url:
            # Re-editing: Use existing image from Spaces
            logger.info(f"🔄 Re-editing existing image from URL: {image_url}")

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
                    image_data = self.storage_service.download_image_as_bytes(image_url)
                    logger.info(f"✅ Image downloaded: {len(image_data)} bytes")
                    original_image_url = image_url  # Reuse existing URL
                except Exception as e:
                    raise ValueError(f"Failed to download image from Spaces: {str(e)}")
        else:
            # New upload: Upload original image to Spaces
            logger.info("📤 Processing new image upload...")

            # Validate image
            if not self.validate_image(image_data):
                raise ValueError("Invalid image or image too large (max 2048x2048)")

            # Upload original image to Spaces
            if self.storage_service:
                try:
                    logger.info("📤 Uploading original image to Spaces...")
                    original_image_url = self.storage_service.upload_image_from_bytes(
                        image_data, user_id, image_type="original"
                    )
                    logger.info(f"✅ Original image uploaded: {original_image_url}")
                except Exception as e:
                    logger.warning(f"⚠️ Failed to upload original image: {e}")

        # Get file info for logging
        image_info = self.get_image_info(image_data)
        audio_info = audio_service.get_audio_info(audio_data, audio_filename)
        logger.info(f"Processing image: {image_info}")
        logger.info(f"Processing audio: {audio_info}")

        # Fetch tutorial subject if tutorial_id is provided
        subject = None
        if tutorial_id:
            tutorial = await Tutorial.get_by_id(db, tutorial_id)
            if tutorial:
                subject = tutorial.subject_en
                logger.info(f"📚 Tutorial subject: {subject}")

        # Step 2: Transcribe audio to text
        transcribed_text, transcription_time = audio_service.transcribe_audio(
            audio_data, language, audio_filename
        )
        logger.info(f"🎤 Transcribed: '{transcribed_text}'")

        # Step 3: Enhance the transcribed text with GPT (short, preservation-focused)
        enhanced_prompt = self.enhance_voice_prompt(transcribed_text, subject)

        # Step 3: Process the image with the transcribed text
        result_base64, processing_time = self.process_image(
            image_data, enhanced_prompt
        )

        # Step 4: Upload edited image to Spaces
        edited_image_url = None
        if self.storage_service:
            try:
                logger.info("📤 Uploading edited image to Spaces...")
                edited_image_url = self.storage_service.upload_image_from_base64(
                    result_base64, user_id, image_type="edited"
                )
                logger.info(f"✅ Edited image uploaded: {edited_image_url}")
            except Exception as e:
                logger.warning(f"⚠️ Failed to upload edited image: {e}")

        # Step 5: Save drawing to database with URLs
        if drawing_id:
            # Re-editing: Fetch existing drawing and append to edited_images_urls
            logger.info(f"📝 Appending audio edit to existing drawing: {drawing_id}")

            try:
                # Fetch the existing drawing
                existing_drawing = await Drawing.get_by_id(db, drawing_id)

                if not existing_drawing:
                    raise ValueError(f"Drawing with ID {drawing_id} not found")

                # Verify the drawing belongs to the current user
                if existing_drawing.user_id != user_id:
                    raise ValueError("Drawing does not belong to the current user")

                # Get current edited_images_urls or initialize as empty list
                current_edits = existing_drawing.edited_images_urls or []

                # Append the new edited image URL
                new_edited_url = edited_image_url if edited_image_url else result_base64
                current_edits.append(new_edited_url)

                # Mark array as modified for PostgreSQL before updating
                attributes.flag_modified(existing_drawing, "edited_images_urls")

                # Update the drawing using the update method
                saved_drawing = await Drawing.update(
                    db, drawing_id, {"edited_images_urls": current_edits}
                )

                logger.info(
                    f"✅ Audio edit appended to drawing. Total edits: {len(current_edits)}"
                )

            except Exception as e:
                logger.error(
                    f"❌ Failed to append audio edit to existing drawing: {str(e)}"
                )
                raise ValueError(f"Failed to append edit to drawing: {str(e)}")
        else:
            # New drawing: Create a new entry
            logger.info("📝 Creating new drawing entry with audio edit")
            saved_drawing = await Drawing.create(
                db,
                user_id=user_id,
                tutorial_id=tutorial_id,
                uploaded_image_url=original_image_url,
                edited_images_urls=(
                    [edited_image_url] if edited_image_url else [result_base64]
                ),
            )

        total_time = transcription_time + processing_time

        return {
            "drawing_id": str(saved_drawing.id),
            "original_image_url": original_image_url,
            "edited_image_url": edited_image_url,
            "prompt": transcribed_text,
            "processing_time": total_time,
        }

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

        drawing = await Drawing.create(
            db,
            user_id=user_id,
            tutorial_id=tutorial_id,
            uploaded_image_url="",
            edited_images_urls=[result_base64],
        )
        return drawing
