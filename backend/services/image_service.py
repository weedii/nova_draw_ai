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

        # Complete instructions from original working code - enhanced for kids
        if step_number == 1:
            prompt = (
                f"⚠️ CRITICAL STEP 1 INSTRUCTION ⚠️\n"
                f"This is ONLY step 1 of a multi-step tutorial. DO NOT draw a complete {subject}!\n"
                f"\n"
                f"TASK FOR STEP 1: {step_description}\n"
                f"\n"
                f"🚫 WHAT YOU MUST NOT DRAW (FORBIDDEN IN STEP 1):\n"
                f"For a FISH: NO tail, NO fins, NO eyes, NO mouth, NO scales\n"
                f"For a CAT: NO eyes, NO nose, NO mouth, NO whiskers, NO body (if step says only head)\n"
                f"For a DRAGON: NO wings, NO legs, NO tail, NO eyes, NO spikes (if step says only head/body)\n"
                f"For ANY subject: NO features that will come in future steps!\n"
                f"\n"
                f"✅ WHAT YOU MUST DRAW (ONLY THIS):\n"
                f"Read the description word by word: {step_description}\n"
                f"- If it says 'oval body', draw ONLY an oval shape - NOTHING attached to it!\n"
                f"- If it says 'round head', draw ONLY a round shape - NOTHING attached to it!\n"
                f"- Draw the SHAPE ONLY - no decorations, no features, no additions!\n"
                f"\n"
                f"EXAMPLE FOR FISH BODY:\n"
                f"- Task: 'Draw a big oval body in the center, lying sideways'\n"
                f"- ✅ CORRECT: Just draw one simple oval shape lying sideways - NOTHING ELSE\n"
                f"- ❌ WRONG: Drawing oval + tail (tail comes in step 2!)\n"
                f"- ❌ WRONG: Drawing oval + fins (fins come later!)\n"
                f"- ❌ WRONG: Drawing anything that looks like a complete fish\n"
                f"\n"
                f"EXAMPLE FOR CAT HEAD:\n"
                f"- Task: 'Draw a round head with two triangle ears'\n"
                f"- ✅ CORRECT: Round circle + two triangle shapes on top - NOTHING ELSE\n"
                f"- ❌ WRONG: Adding eyes (eyes come in step 2!)\n"
                f"- ❌ WRONG: Adding body (body comes later!)\n"
                f"\n"
                f"WHY THIS MATTERS:\n"
                f"Kids will draw this step, then add more in the next steps. If you draw extra parts now, the tutorial won't work!\n"
                f"\n"
                f"STYLE:\n"
                f"- White background, black lines only\n"
                f"- Fun curved shapes - wiggly, bouncy, cartoon style (not geometric)\n"
                f"- Simple enough for a 5-year-old\n"
                f"- No text or labels\n"
                f"\n"
                f"⚠️ FINAL CHECK: Does your drawing have ONLY what the step description says?\n"
                f"If you added ANYTHING extra (tail, fins, eyes, etc.), you did it WRONG!\n"
                f"Draw ONLY the shape described - kids will add the rest later!"
            )
        else:
            prompt = (
                f"⚠️ CRITICAL PRESERVATION INSTRUCTION ⚠️\n"
                f"This is step {step_number} of a multi-step tutorial. The previous image is SACRED - do NOT change it!\n"
                f"\n"
                f"🚫 ABSOLUTELY FORBIDDEN - NEVER DO THESE:\n"
                f"- DO NOT redraw, modify, improve, or 'fix' ANY existing element\n"
                f"- DO NOT change the shape, size, position, or style of ANY existing line\n"
                f"- DO NOT erase or remove ANY existing element\n"
                f"- DO NOT move or reposition ANY existing element\n"
                f"- DO NOT change line thickness or curve of existing elements\n"
                f"- DO NOT 'improve' or 'enhance' existing parts\n"
                f"- DO NOT redraw the body, head, tail, or ANY part that already exists\n"
                f"\n"
                f"✅ YOUR ONLY JOB:\n"
                f"1. COPY the previous image EXACTLY as it is - pixel-perfect, line-for-line\n"
                f"2. ADD ONLY the new element described below: {step_description}\n"
                f"3. Place the new element relative to existing ones WITHOUT touching them\n"
                f"\n"
                f"TASK FOR THIS STEP: {step_description}\n"
                f"- Read carefully: ONLY add what's described\n"
                f"- If it says 'add fins', add ONLY fins - don't touch the body or tail!\n"
                f"- If it says 'add eyes', add ONLY eyes - don't touch the head or body!\n"
                f"- If it says 'add a tail', add ONLY a tail - don't modify the body!\n"
                f"\n"
                f"EXAMPLE OF WHAT TO DO:\n"
                f"- Previous image has: oval body\n"
                f"- Task: 'add a tail'\n"
                f"- You draw: EXACT same oval body + NEW tail attached\n"
                f"- You DO NOT: redraw the body, change the body shape, 'improve' the body\n"
                f"\n"
                f"EXAMPLE OF WHAT NOT TO DO:\n"
                f"- Previous image has: oval body and tail\n"
                f"- Task: 'add fins'\n"
                f"- ❌ WRONG: Redraw body, change tail shape, then add fins\n"
                f"- ✅ RIGHT: Keep body and tail EXACTLY as they are, add fins only\n"
                f"\n"
                f"STYLE FOR NEW ELEMENTS:\n"
                f"- White background, black lines only\n"
                f"- Fun curved shapes - wiggly, bouncy, cartoon style\n"
                f"- Match existing style but DON'T change existing elements!\n"
                f"\n"
                f"⚠️ FINAL WARNING: If you change ANY existing element, the tutorial is RUINED!\n"
                f"Kids are following step-by-step - they need consistency!\n"
                f"COPY the previous image exactly, ADD only what's described!"
            )

        # Add previous image if this isn't the first step
        if step_number == 1:
            contents = [prompt]
            print(f"🎨 Generating fresh image for step {step_number}")
            print(f"   Subject: {subject}")
            print(f"   Task: {step_description}")
        else:
            if not previous_image_path or not Path(previous_image_path).exists():
                raise ValueError(f"Step {step_number} needs previous image!")

            previous_image = Image.open(previous_image_path)
            contents = [prompt, previous_image]
            print(f"🔗 Editing previous image for step {step_number}")
            print(f"   Subject: {subject}")
            print(f"   Task: {step_description}")
            print(f"   Building on: {Path(previous_image_path).name}")

        # Call Nano Banana API
        print("⏳ Calling Nano Banana API...")
        start_time = time.time()

        response = self.client.models.generate_content(
            model=self.model,
            contents=contents,
        )

        duration = time.time() - start_time
        print(f"⚡ API Response Time: {duration:.2f} seconds")

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

                    # Convert to grayscale to remove colors, then back to RGB
                    result_image = result_image.convert("L").convert("RGB")

                    # Save the image
                    filename_subject = subject.lower().replace(" ", "_")
                    sanitized_subject = sanitize_filename(filename_subject)
                    filename = f"step_{step_number:02d}_{sanitized_subject}.png"
                    file_path = session_folder / filename

                    result_image.save(file_path, "PNG")
                    print(f"💾 Image saved: {file_path}")

                    # Convert to base64 for response
                    import base64

                    buffered = BytesIO()
                    result_image.save(buffered, format="PNG")
                    img_base64 = base64.b64encode(buffered.getvalue()).decode("utf-8")

                    print(f"✅ Step {step_number} completed successfully")
                    print(f"   Image size: {result_image.size}")
                    print(f"   Base64 length: {len(img_base64)} characters")

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
