import time
from pathlib import Path
from PIL import Image
from io import BytesIO
from google import genai
from typing import Optional
from src.core.config import settings
from src.utils.file_operations import sanitize_filename
from src.prompts import (
    get_step_image_generation_prompt_first_step,
    get_step_image_editing_prompt_subsequent_steps,
)


class ImageService:
    """Service for generating step images using Google Gemini Nano Banana"""

    def __init__(self):
        self.client = genai.Client(api_key=settings.GOOGLE_API_KEY)
        self.model = "gemini-2.5-flash-image-preview"

    def generate_step_image(
        self,
        step_description: str,
        subject: str,
        step_number: int,
        session_folder: Path,
        previous_image_path: Optional[str] = None,
    ) -> tuple[str, str, float]:
        """
        Generate a black-and-white kid-friendly image for a drawing step.
        Uses iterative editing for multi-turn consistency.
        Returns (image_path, base64_image, generation_time)
        """

        # For first step - generate fresh
        if step_number == 1:
            prompt = get_step_image_generation_prompt_first_step(
                step_description, subject, step_number
            )
            contents = [prompt]

        # For subsequent steps - edit previous image
        else:
            if not previous_image_path or not Path(previous_image_path).exists():
                raise ValueError(
                    f"Step {step_number} requires previous image, but no previous image available!"
                )

            prompt = get_step_image_editing_prompt_subsequent_steps(
                step_description, subject, step_number
            )
            previous_image = Image.open(previous_image_path)
            contents = [prompt, previous_image]

        # Call Nano Banana API
        start_time = time.time()

        response = self.client.models.generate_content(
            model=self.model,
            contents=contents,
        )

        duration = time.time() - start_time

        # Extract and save the image
        for part in response.candidates[0].content.parts:
            if part.inline_data is not None:
                try:
                    # Get the raw image data
                    image_data = part.inline_data.data

                    # Debug: Check the first few bytes to identify format
                    print(f"First 20 bytes: {image_data[:20]}")
                    print(f"Image data type: {type(image_data)}")
                    print(f"Image data length: {len(image_data)}")

                    # Check if data is already binary (starts with PNG header) or needs base64 decoding
                    import base64

                    # Check if it's already binary PNG data (starts with PNG signature)
                    if isinstance(image_data, bytes) and image_data.startswith(
                        b"\x89PNG"
                    ):
                        print("Image data is already in binary PNG format")
                        # Use data as-is
                        pass
                    else:
                        # Try base64 decoding if it's not already binary PNG
                        try:
                            decoded_data = base64.b64decode(image_data)
                            print(
                                f"Successfully decoded base64, new length: {len(decoded_data)}"
                            )
                            print(f"First 20 bytes after decode: {decoded_data[:20]}")

                            # Verify the decoded data is valid PNG
                            if decoded_data.startswith(b"\x89PNG"):
                                image_data = decoded_data
                                print("Base64 decoded data is valid PNG")
                            else:
                                print("Base64 decoded data is not PNG, using original")
                        except Exception as b64_error:
                            print(
                                f"Base64 decode failed: {b64_error}, using original data"
                            )

                    # Create BytesIO object and reset position to beginning
                    image_bytes = BytesIO(image_data)
                    image_bytes.seek(0)  # Critical: Reset stream position to beginning

                    # Try to open with PIL
                    result_image = Image.open(image_bytes)
                    print(
                        f"Successfully opened image: {result_image.format} {result_image.size} {result_image.mode}"
                    )

                    # Convert to RGB if necessary (some formats might need this)
                    if result_image.mode != "RGB":
                        result_image = result_image.convert("RGB")

                    # Save the image
                    filename_subject = subject.lower().replace(" ", "_")
                    sanitized_subject = sanitize_filename(filename_subject)
                    filename = f"step_{step_number:02d}_{sanitized_subject}.png"
                    file_path = session_folder / filename

                    result_image.save(file_path, "PNG")
                    print(f"Successfully saved image to: {file_path}")

                    # Convert to base64 for response
                    import base64

                    buffered = BytesIO()
                    result_image.save(buffered, format="PNG")
                    img_base64 = base64.b64encode(buffered.getvalue()).decode("utf-8")

                    return str(file_path), img_base64, duration

                except Exception as img_error:
                    print(f"Error processing image data: {img_error}")
                    print(f"Image data type: {type(image_data)}")
                    print(
                        f"Image data length: {len(image_data) if hasattr(image_data, '__len__') else 'Unknown'}"
                    )

                    # Try to save raw data for debugging
                    try:
                        debug_file = session_folder / f"debug_step_{step_number}.raw"
                        with open(debug_file, "wb") as f:
                            f.write(image_data)
                        print(f"Saved raw data to: {debug_file}")
                    except Exception as save_error:
                        print(f"Could not save debug file: {save_error}")

                    raise ValueError(f"Failed to process image data: {img_error}")

        raise ValueError("No image data received in response")
