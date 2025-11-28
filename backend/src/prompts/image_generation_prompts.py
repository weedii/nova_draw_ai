"""
Image generation service prompts for step-by-step drawing tutorials.

This module contains prompts used by the ImageService for:
- Generating initial step images (step 1)
- Editing images for subsequent steps (steps 2+)
"""


def get_step_image_generation_prompt_first_step(
    step_description: str, subject: str, step_number: int
) -> str:
    """
    Get the prompt for generating the first step image.

    For the first step, we generate a fresh image without any previous context.

    Args:
        step_description: Description of what to draw in this step
        subject: The subject being drawn (e.g., "dog", "cat")
        step_number: The step number (should be 1)

    Returns:
        str: Prompt for Gemini image generation
    """

    return (
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


def get_step_image_editing_prompt_subsequent_steps(
    step_description: str, subject: str, step_number: int
) -> str:
    """
    Get the prompt for editing images in subsequent steps.

    For steps 2+, we edit the previous image to add new elements while
    preserving all existing elements exactly.

    Args:
        step_description: Description of what to add in this step
        subject: The subject being drawn (e.g., "dog", "cat")
        step_number: The step number (2 or higher)

    Returns:
        str: Prompt for Gemini image editing
    """

    return (
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
