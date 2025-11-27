"""
Image processing service prompts for Gemini and OpenAI APIs.

This module contains prompts used by the ImageProcessingService for:
- Voice prompt enhancement (GPT-3.5-turbo)
- Image processing with Gemini
"""


def get_voice_prompt_enhancement_prompt(user_request: str, subject: str = None) -> str:
    """
    Get the prompt for enhancing voice input into a focused editing prompt.

    This prompt is used with GPT-3.5-turbo to create short, preservation-focused
    prompts that won't lose the drawing's identity.

    Args:
        user_request: Transcribed voice request (e.g., "put it in Paris")
        subject: What the child drew (e.g., "dog", "cat") - from tutorial

    Returns:
        str: Enhancement prompt for OpenAI API
    """

    # Build context about what was drawn
    subject_context = f"a {subject}" if subject else "their picture"

    return f"""A child just drew {subject_context} and said: "{user_request}"

Generate a prompt (3-4 sentences) for an image editing AI.

CRITICAL: You MUST follow exactly what the child asked for. Do NOT make up your own ideas.

RULES:
- FOLLOW THE CHILD'S REQUEST - do exactly what they asked, not something else
- Keep the child's original drawing recognizable
- Add vibrant colors, sparkles, and fun details to make it magical
- Keep it kid-friendly and full of wonder
- Understand child language: "put in paris" = "place in Paris", "make alive" = "bring to life"

IMPORTANT: Output ONLY the prompt text. No prefixes or labels.

EXAMPLES:
Child says "make cat chasing mouse" → "Show this child's cat in an exciting chase scene with a cute little mouse! Add motion lines to show speed. Give the cat bright playful eyes and the mouse a funny scared expression. Add colorful background."

Child says "put dog in paris" → "Transport this child's dog to magical Paris! Add the sparkling Eiffel Tower in the background. Give the dog warm golden fur. Add pink sunset clouds."

Child says "make flower rainbow" → "Transform this child's flower with beautiful rainbow colors! Flow vibrant colors through the petals. Add sparkles and a soft magical glow."
"""


def get_image_processing_prompt(edit_prompt: str) -> str:
    """
    Get the prompt for processing an image with Gemini.

    This prompt wraps the detailed edit instructions from the database with
    preservation guidelines to ensure the child's drawing remains recognizable.

    Args:
        edit_prompt: The detailed editing instructions (from edit_options table)

    Returns:
        str: Full prompt for Gemini image processing
    """

    return f"""
You are editing a child's hand-drawn picture for a kids' creativity app.

CRITICAL RULES:
1. PRESERVE THE ORIGINAL DRAWING - Keep the child's original lines, shapes, and proportions intact
2. DO NOT redraw or replace the main subject - only enhance/add to it
3. The child's drawing style must remain recognizable
4. Keep it kid-friendly, fun, and magical

YOUR TASK:
{edit_prompt}

TECHNICAL REQUIREMENTS:
- Return ONLY the edited image
- No text, watermarks, or labels
- Maintain image quality
"""
