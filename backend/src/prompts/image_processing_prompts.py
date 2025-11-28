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
    prompts that guide the AI toward vibrant, imaginative transformations.

    Args:
        user_request: Transcribed voice request (e.g., "put it in Paris")
        subject: What the child drew (e.g., "dog", "cat") - from tutorial

    Returns:
        str: Enhancement prompt for OpenAI API
    """

    # Build context about what was drawn
    subject_context = f"a {subject}" if subject else "their picture"

    return f"""A child just drew {subject_context} and said: "{user_request}"

Generate a prompt (4-5 sentences) for an image editing AI that will enhance the drawing into a vibrant, imaginative artwork.

CRITICAL RULES:
1. You MUST follow exactly what the child asked for - do NOT make up your own ideas
2. The child's original drawing must remain RECOGNIZABLE and in the SAME POSE
3. Think of this as "coloring and polishing" the drawing, not redrawing it
4. The result should look like an enhanced version of the original, NOT a completely new image
5. NEVER rotate or change the orientation of the drawing - keep it in the same orientation

CRITICAL CONSTRAINT - EDIT, DON'T RECREATE:
- If the request is to transform (e.g., "make it a fighter jet"), EDIT the existing drawing
- Don't create a completely new object - enhance the uploaded one
- Keep the child's original drawing style and structure visible
- Add details and modifications to the existing drawing, not replace it

ENHANCEMENT RULES:
- Keep the child's original drawing as the foundation
- Add vibrant colors, gradients, glows, and sparkles to enhance it
- Add small details and effects that don't obscure the original
- Make it look polished and colorful (animated style, not photorealistic)
- Include personality and energy - make it look alive and joyful
- Add a simple, colorful background that complements the character
- Keep it kid-friendly and full of wonder
- Understand child language: "put in paris" = "place in Paris", "make alive" = "bring to life", "colorful" = "vibrant colors"

IMPORTANT: Output ONLY the prompt text. No prefixes or labels.

EXAMPLES:
Child says "make cat chasing mouse" → "Enhance this child's cat by adding vibrant colors and polishing it. Keep the cat's original shape, pose, and orientation exactly recognizable. Add a cute little mouse nearby and motion lines to show action. Give the cat bright, expressive eyes. Add a simple colorful background with sparkles and magical effects. Make it look alive and joyful while keeping the child's drawing clearly visible and in the same orientation."

Child says "put dog in paris" → "Enhance this child's dog with vibrant colors and polishing. Keep the dog's original shape, pose, and orientation exactly recognizable. Add the Eiffel Tower in the background with golden lights. Give the dog warm, colorful fur with gradients. Add pink and purple sunset clouds and sparkles. Make it look magical while the child's original drawing remains the clear focus in the same orientation."

Child says "make flower rainbow" → "Enhance this child's flower by adding beautiful rainbow colors to the petals. Keep the flower's original shape, structure, and orientation recognizable. Add sparkles and glows around the flower. Create a simple, colorful background. Make it look vibrant and magical while keeping the child's drawing clearly visible and in the same orientation."

Child says "make it a fighter jet" → "Enhance this child's airplane by adding fighter jet details to it. Keep the airplane's original shape and orientation exactly recognizable. Add sleek details, weapons, and military markings to make it look like a fighter jet. Give it vibrant metallic colors and glows. Add a dynamic background with clouds and effects. Make it look powerful and cool while the child's original airplane drawing remains clearly visible."

Child says "make it colorful" → "Enhance this child's drawing by adding vibrant, bold colors and polishing it. Keep the original drawing recognizable, in the same pose, and in the same orientation. Add gradients, glows, and sparkles throughout. Include a simple, colorful background. Make it look animated and full of personality while the child's original drawing remains clearly visible."
"""


def get_image_processing_prompt(edit_prompt: str) -> str:
    """
    Get the prompt for processing an image with Gemini.

    This prompt wraps the detailed edit instructions from the database with
    preservation guidelines to ensure the child's drawing remains recognizable
    while transforming it into a vibrant, imaginative artwork.

    Args:
        edit_prompt: The detailed editing instructions (from edit_options table)

    Returns:
        str: Full prompt for Gemini image processing
    """

    return f"""You are an artist enhancing a child's hand-drawn picture into a vibrant, stylized artwork for a kids' creativity app.

CRITICAL PRIORITY - PRESERVE THE ORIGINAL DRAWING:
1. Keep the child's original character/subject EXACTLY recognizable
2. Maintain the EXACT SAME POSE and proportions
3. Keep all the child's original lines and shapes visible
4. The edited version should look like an enhanced version of the original, NOT a completely new image
5. A child should immediately recognize their own drawing in the result

CRITICAL CONSTRAINT - PRESERVE ORIENTATION:
- NEVER rotate the drawing horizontally or vertically
- Keep the drawing in the EXACT SAME ORIENTATION as the original
- If the airplane was drawn pointing right, keep it pointing right (don't rotate it)
- If the character was upright, keep it upright (don't tilt or rotate it)
- Only add enhancements, effects, and details - NO rotations or orientation changes

CRITICAL CONSTRAINT - EDIT, DON'T RECREATE:
- If asked to transform (e.g., "airplane" → "fighter jet"), EDIT the existing drawing
- Don't create a completely new airplane - enhance the uploaded one
- Keep the child's original drawing style and structure visible
- Add details and modifications to the existing drawing, not replace it
- Example: If child drew a simple airplane, make it look like a fighter jet by adding details to THAT airplane, not drawing a new one

ENHANCEMENT APPROACH:
- Think of this as "coloring and polishing" the child's drawing, not redrawing it
- Add colors, details, and effects AROUND and WITHIN the existing lines
- Enhance what's already there, don't replace it
- Keep the child's drawing style visible (hand-drawn feel)

ARTISTIC ENHANCEMENTS (while preserving original):
- Add vibrant colors and gradients to existing shapes
- Add atmospheric effects: glows, sparkles, light rays (subtle, not overwhelming)
- Include small dynamic elements that don't obscure the original
- Add depth with gentle shadows and layering
- Enhance the character's personality through expression and details
- Use smooth, polished rendering (digital art style, not realistic)
- Add a simple, colorful background that doesn't compete with the character

YOUR TASK:
{edit_prompt}

IMPORTANT REMINDERS:
- The original drawing must be the foundation - everything else builds on it
- If the child drew a simple stick figure, it should still be recognizable as a stick figure (just enhanced)
- If the child drew a cat, it should still look like their cat (just more colorful and polished)
- If the child drew an airplane, it should still look like their airplane (just enhanced with fighter jet details)
- NEVER rotate or change the orientation of the drawing
- Keep it kid-friendly, joyful, and full of wonder
- Add special effects and magical elements that enhance, not replace

TECHNICAL REQUIREMENTS:
- Return ONLY the edited image
- No text, watermarks, or labels
- Maintain high image quality
- The child's original drawing must be clearly visible and recognizable in the result
- The drawing must be in the EXACT SAME ORIENTATION as the original
"""
