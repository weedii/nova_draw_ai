"""
Prompts module - Centralized prompt management for all AI services.

This module contains all prompts used by the backend services:
- audio_prompts: Audio transcription and enhancement prompts
- image_processing_prompts: Image editing and processing prompts
- drawing_prompts: Drawing step generation and translation prompts
- story_prompts: Children's story generation prompts
- image_generation_prompts: Step-by-step drawing image generation prompts
"""

# Audio prompts
from src.prompts.audio_prompts import (
    get_prompt_enhancement_prompt_de,
    get_prompt_enhancement_prompt_en,
    get_prompt_enhancement_user_message,
)

# Image processing prompts
from src.prompts.image_processing_prompts import (
    get_image_processing_prompt_en,
    get_image_processing_prompt_de,
)

# Drawing prompts
from src.prompts.drawing_prompts import (
    get_drawing_steps_generation_prompt,
    get_german_translation_prompt,
)

# Story prompts
from src.prompts.story_prompts import (
    get_story_generation_prompt_de,
    get_story_generation_prompt_en,
    get_story_generation_prompt,
)

# Image generation prompts
from src.prompts.image_generation_prompts import (
    get_step_image_generation_prompt_first_step,
    get_step_image_editing_prompt_subsequent_steps,
)

__all__ = [
    # Audio prompts
    "get_prompt_enhancement_prompt_de",
    "get_prompt_enhancement_prompt_en",
    "get_prompt_enhancement_user_message",
    # Image processing prompts
    "get_voice_prompt_enhancement_prompt",
    "get_image_processing_prompt_en",
    "get_image_processing_prompt_de",
    # Drawing prompts
    "get_drawing_steps_generation_prompt",
    "get_german_translation_prompt",
    # Story prompts
    "get_story_generation_prompt_de",
    "get_story_generation_prompt_en",
    "get_story_generation_prompt",
    # Image generation prompts
    "get_step_image_generation_prompt_first_step",
    "get_step_image_editing_prompt_subsequent_steps",
]
