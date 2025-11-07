import time
import base64
import logging
from pathlib import Path
from PIL import Image
from io import BytesIO
from google import genai
from openai import OpenAI
from typing import Tuple
from config import settings

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class ImageProcessingService:
    """Service for processing images using Google Gemini"""

    def __init__(self):
        logger.info("Initializing ImageProcessingService...")

        if not settings.google_api_key:
            logger.error("Google API key is missing")
            raise ValueError("Google API key is required for image processing")
        if not settings.openai_api_key:
            logger.error("OpenAI API key is missing")
            raise ValueError("OpenAI API key is required for prompt enhancement")

        self.gemini_client = genai.Client(api_key=settings.google_api_key)
        self.openai_client = OpenAI(api_key=settings.openai_api_key)
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
            You are creating image editing prompts for a children's app designed for kids aged 4-8 years old. Convert simple user requests into detailed, kid-friendly prompts that will create magical, fun, and age-appropriate image transformations.

            The child wants to: "{user_prompt}"

            Convert this into a detailed prompt for an AI image editor that creates SAFE, FUN, and KID-FRIENDLY results. Include:
            - Bright, cheerful colors and effects
            - Magical, whimsical elements that kids love
            - Safe, positive transformations only
            - Fun visual effects like sparkles, rainbows, cute elements
            - Age-appropriate enhancements

            SAFETY RULES - NEVER include:
            - Scary, dark, or frightening elements
            - Violence, weapons, or dangerous items
            - Adult themes or inappropriate content
            - Realistic gore, blood, or disturbing imagery
            - Anything that might upset or frighten young children

            FOCUS ON - ALWAYS include:
            - Bright, happy colors
            - Cute, friendly characters or elements
            - Magical effects like sparkles, glitter, rainbows
            - Cartoon-style, child-friendly aesthetics
            - Positive, uplifting transformations
            - Fun, playful visual elements

            Examples for kids:
            - "make it alive" → "Transform this image to make it come ALIVE with big, friendly sparkling eyes full of joy, a happy smile, cute rosy cheeks, gentle movement effects like flowing hair or swaying in a happy breeze, bright cheerful colors, magical sparkles around it, and a warm, welcoming expression that makes it look like a friendly cartoon character"
            - "make it colorful" → "Transform this image into a rainbow wonderland with bright happy colors like pink, blue, yellow, and green, add rainbow gradients, colorful butterflies or flowers, sparkling glitter effects, cheerful sunshine rays, and make everything look like a magical fairy tale with vibrant, kid-friendly cartoon colors"
            - "make it magical" → "Add magical fairy tale elements like sparkling fairy dust, rainbow colors, cute stars and hearts floating around, gentle glowing effects, magical wands or crowns, friendly unicorns or butterflies, and make it look like something from a happy children's storybook"

            Return ONLY the enhanced kid-friendly prompt, no explanations or extra text.
            """

            logger.info(f"📤 Sending enhancement request to {self.openai_model}")

            response = self.openai_client.chat.completions.create(
                model=self.openai_model,
                messages=[{"role": "user", "content": enhancement_prompt}],
                max_tokens=300,
                temperature=0.7,  # Creative but controlled
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
            You are a professional AI image editor and digital artist.
            
            Transform the uploaded image with these detailed instructions:
            {enhanced_prompt}
            
            Additional guidelines:
            - Make significant and obvious visual changes
            - Maintain the core subject while transforming it dramatically
            - Use professional image editing techniques
            - Make the result visually stunning and impactful
            - Return ONLY the processed image, no text or watermarks
            - Apply all the specified effects and enhancements
            
            Transform the image now according to these detailed instructions.
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
            return {"error": str(e)}
