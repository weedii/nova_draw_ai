import time
import base64
from pathlib import Path
from PIL import Image
from io import BytesIO
from google import genai
from typing import Tuple
from config import settings


class ImageProcessingService:
    """Service for processing images using Google Gemini"""

    def __init__(self):
        if not settings.google_api_key:
            raise ValueError("Google API key is required for image processing")

        self.client = genai.Client(api_key=settings.google_api_key)
        self.model = "gemini-2.5-flash-image-preview"

    def process_image(self, image_data: bytes, prompt: str) -> Tuple[str, float]:
        """
        Process an image with a text prompt using Gemini.

        Args:
            image_data: Raw image bytes
            prompt: Text prompt for processing (e.g., "make it alive")

        Returns:
            Tuple of (base64_result_image, processing_time)
        """
        start_time = time.time()

        try:
            # Convert bytes to PIL Image
            input_image = Image.open(BytesIO(image_data))

            # Ensure image is in RGB mode
            if input_image.mode != "RGB":
                input_image = input_image.convert("RGB")

            # Create a simple, direct prompt that uses the user's request
            full_prompt = f"""
            You are a professional AI image editor and digital artist.
            
            The user wants you to: "{prompt}"
            
            Please transform the uploaded image according to this request. Be creative and make the transformation obvious and impactful.
            
            Guidelines:
            - Follow the user's request literally and creatively
            - Make significant visual changes that are clearly visible
            - Maintain the core subject while transforming it
            - Use professional image editing techniques
            - Make the result visually stunning
            - Return ONLY the processed image, no text or watermarks
            
            Transform the image now.
            """

            # Prepare content for Gemini
            contents = [full_prompt, input_image]

            # Call Gemini API
            response = self.client.models.generate_content(
                model=self.model,
                contents=contents,
            )

            duration = time.time() - start_time

            # Extract and process the result image
            for part in response.candidates[0].content.parts:
                if part.inline_data is not None:
                    try:
                        # Get the raw image data
                        result_image_data = part.inline_data.data

                        # Handle different data formats
                        if isinstance(
                            result_image_data, bytes
                        ) and result_image_data.startswith(b"\x89PNG"):
                            # Already binary PNG data
                            processed_data = result_image_data
                        else:
                            # Try base64 decoding
                            try:
                                processed_data = base64.b64decode(result_image_data)
                                if not processed_data.startswith(b"\x89PNG"):
                                    # If not PNG after decoding, use original
                                    processed_data = result_image_data
                            except Exception:
                                processed_data = result_image_data

                        # Convert to PIL Image and then to base64
                        result_image = Image.open(BytesIO(processed_data))

                        # Convert to RGB if necessary
                        if result_image.mode != "RGB":
                            result_image = result_image.convert("RGB")

                        # Convert to base64 for response
                        buffered = BytesIO()
                        result_image.save(buffered, format="PNG")
                        img_base64 = base64.b64encode(buffered.getvalue()).decode(
                            "utf-8"
                        )

                        return img_base64, duration

                    except Exception as img_error:
                        raise ValueError(f"Failed to process result image: {img_error}")

            raise ValueError("No image data received in response")

        except Exception as e:
            duration = time.time() - start_time
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
