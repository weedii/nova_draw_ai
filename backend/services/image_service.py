import time
from pathlib import Path
from PIL import Image
from io import BytesIO
from google import genai
from typing import Optional
from config import settings
from utils import sanitize_filename


class ImageService:
    """Service for generating step images using Google Gemini Nano Banana"""

    def __init__(self):
        self.client = genai.Client(api_key=settings.google_api_key)
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
            prompt = (
                f"We are creating a step-by-step drawing tutorial to teach kids how to draw a {subject}. "
                f"This is step {step_number} of the tutorial. "
                f"Your task: {step_description} "
                f"CRITICAL: ONLY ADD what is described in this step. NEVER modify, erase, or change anything. "
                f"Do not add elements from future steps. Do not remove or alter any existing elements. "
                f"Do NOT include any text, labels, or words in the image. Only draw the shapes and lines. "
                f"Background: Pure white background - no patterns, textures, or colors in the background. "
                f"Style: Clean, engaging black line drawing with personality, cartoon style, no shading or color fill. "
                f"Use only black lines on pure white background - no gray tones or colored areas. "
                f"Make the drawing look fun and appealing while still being simple enough for children to copy. "
                f"Avoid overly geometric shapes - use curved lines, expressive features, and natural proportions. "
                f"Show only what is described in this specific step, but make it look good and engaging."
            )
            contents = [prompt]

        # For subsequent steps - edit previous image
        else:
            if not previous_image_path or not Path(previous_image_path).exists():
                raise ValueError(
                    f"Step {step_number} requires previous image, but no previous image available!"
                )

            prompt = (
                f"CRITICAL: You are editing step {step_number} of a {subject} drawing tutorial. "
                f"The previous image shows the result of steps 1-{step_number-1}. "
                f"ABSOLUTE PRESERVATION RULE: Copy the previous image EXACTLY - every single line, curve, shape, and detail must remain 100% identical. "
                f"ONLY ADD: {step_description} "
                f"FORBIDDEN ACTIONS (NEVER DO THESE): "
                f"- Do NOT erase, remove, or delete ANY existing lines or shapes "
                f"- Do NOT modify, change, or alter ANY existing elements "
                f"- Do NOT move, resize, or reposition ANY existing elements "
                f"- Do NOT redraw, update, or improve ANY existing elements "
                f"- Do NOT change the style, thickness, or appearance of existing lines "
                f"ALLOWED ACTIONS (ONLY THESE): "
                f"- ADD new elements exactly as described in the step "
                f"- Position new elements relative to existing ones WITHOUT touching existing elements "
                f"- Match the existing drawing style for new elements only "
                f"SPECIFIC EXAMPLES: "
                f"- If the step says 'add eyes to the head', the head must remain pixel-perfect identical "
                f"- If the step says 'add legs below the body', the body must stay completely unchanged "
                f"- If the step says 'add a tail', all existing body parts must remain exactly as they were "
                f"Background: Keep the pure white background - no patterns, textures, or colors in the background. "
                f"Style: Clean, engaging black line drawing with personality, cartoon style, no shading or color fill. "
                f"Use only black lines on pure white background - no gray tones or colored areas. "
                f"Make NEW additions look good while leaving ALL existing elements completely untouched. "
                f"REMEMBER: Consistency preservation of existing elements is the highest priority."
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

                    # Check if it's base64 encoded (common with API responses)
                    import base64

                    try:
                        # Try to decode as base64 first
                        decoded_data = base64.b64decode(image_data)
                        print(
                            f"Successfully decoded base64, new length: {len(decoded_data)}"
                        )
                        print(f"First 20 bytes after decode: {decoded_data[:20]}")
                        image_data = decoded_data
                    except Exception as b64_error:
                        print(f"Not base64 encoded: {b64_error}")
                        # Use original data if base64 decode fails
                        pass

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
