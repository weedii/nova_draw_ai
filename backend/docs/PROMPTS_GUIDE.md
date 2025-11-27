# Prompts Guide

## Overview

All AI prompts are centralized in the `src/prompts/` folder. This makes them easy to find, modify, and reuse across services.

## Where Prompts Are Located

```
backend/src/prompts/
├── __init__.py                      # Imports all prompts
├── audio_prompts.py                 # Audio transcription prompts
├── image_processing_prompts.py      # Image editing prompts
├── drawing_prompts.py               # Drawing step generation prompts
├── story_prompts.py                 # Story generation prompts
└── image_generation_prompts.py      # Step image generation prompts
```

## How to Use Existing Prompts

### Import Prompts

```python
# Import from the main prompts module
from src.prompts import get_story_generation_prompt

# Or import multiple prompts
from src.prompts import (
    get_prompt_enhancement_prompt_de,
    get_prompt_enhancement_prompt_en,
    get_story_generation_prompt,
)
```

### Use Prompts in Your Code

```python
# Get a prompt
prompt = get_story_generation_prompt("en")

# Use in API call
response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": prompt}],
)
```

## Available Prompts

### Audio Prompts (`audio_prompts.py`)

- `get_prompt_enhancement_prompt_de()` - German audio enhancement
- `get_prompt_enhancement_prompt_en()` - English audio enhancement
- `get_prompt_enhancement_user_message(text, language)` - User message for enhancement

### Image Processing Prompts (`image_processing_prompts.py`)

- `get_voice_prompt_enhancement_prompt(request, subject)` - Voice to prompt enhancement
- `get_image_processing_prompt(edit_prompt)` - Image editing with Gemini

### Drawing Prompts (`drawing_prompts.py`)

- `get_drawing_steps_generation_prompt(subject)` - Generate drawing steps
- `get_german_translation_prompt(steps_text)` - Translate steps to German

### Story Prompts (`story_prompts.py`)

- `get_story_generation_prompt(language)` - Generate children's stories
- `get_story_generation_prompt_de()` - German story prompt
- `get_story_generation_prompt_en()` - English story prompt

### Image Generation Prompts (`image_generation_prompts.py`)

- `get_step_image_generation_prompt_first_step(description, subject, step)` - First step image
- `get_step_image_editing_prompt_subsequent_steps(description, subject, step)` - Subsequent steps

## How to Add a New Prompt

### Step 1: Identify the Category

Determine which file your prompt belongs to:

- Audio-related → `audio_prompts.py`
- Image editing → `image_processing_prompts.py`
- Drawing steps → `drawing_prompts.py`
- Story generation → `story_prompts.py`
- Step images → `image_generation_prompts.py`
- New category → Create new file `your_category_prompts.py`

### Step 2: Add the Prompt Function

Open the appropriate file and add your function:

```python
def get_my_new_prompt(param1: str, param2: str = "default") -> str:
    """
    Brief description of what this prompt does.

    Args:
        param1: Description of param1
        param2: Description of param2

    Returns:
        str: The prompt text
    """
    return f"""
Your prompt text here.
Use {param1} and {param2} as needed.
"""
```

### Step 3: Export the Function

Add your function to `__init__.py`:

```python
# At the top with other imports from the same file
from src.prompts.your_category_prompts import get_my_new_prompt

# In the __all__ list
__all__ = [
    # ... existing exports ...
    "get_my_new_prompt",
]
```

### Step 4: Use the Prompt

Import and use it in your service:

```python
from src.prompts import get_my_new_prompt

# In your method
prompt = get_my_new_prompt("value1", "value2")
response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": prompt}],
)
```

## Example: Adding a New Prompt

### Scenario: Add a prompt for image captioning

**1. Add to `image_processing_prompts.py`:**

```python
def get_image_captioning_prompt(style: str = "simple") -> str:
    """
    Get the prompt for generating image captions.

    Args:
        style: Caption style ('simple', 'detailed', 'poetic')

    Returns:
        str: Image captioning prompt
    """
    if style == "detailed":
        return """Provide a detailed, descriptive caption for this image..."""
    elif style == "poetic":
        return """Write a poetic caption for this image..."""
    else:
        return """Write a simple, clear caption for this image..."""
```

**2. Update `__init__.py`:**

```python
from src.prompts.image_processing_prompts import (
    get_voice_prompt_enhancement_prompt,
    get_image_processing_prompt,
    get_image_captioning_prompt,  # Add this
)

__all__ = [
    # ... existing ...
    "get_image_captioning_prompt",  # Add this
]
```

**3. Use in your service:**

```python
from src.prompts import get_image_captioning_prompt

# In your method
caption_prompt = get_image_captioning_prompt("detailed")
response = client.chat.completions.create(
    model="gpt-4o-vision",
    messages=[{"role": "user", "content": caption_prompt}],
)
```

## Best Practices

1. **Keep prompts in the module** - Don't hardcode prompts in service files
2. **Use descriptive function names** - Make it clear what the prompt does
3. **Add docstrings** - Document parameters and return values
4. **Group by category** - Keep related prompts in the same file
5. **Reuse functions** - Call other prompt functions if needed
6. **Test your prompts** - Verify they work with the API before committing

## Quick Reference

| Task              | File                          | Function                                |
| ----------------- | ----------------------------- | --------------------------------------- |
| Audio enhancement | `audio_prompts.py`            | `get_prompt_enhancement_prompt_*()`     |
| Image editing     | `image_processing_prompts.py` | `get_image_processing_prompt()`         |
| Drawing steps     | `drawing_prompts.py`          | `get_drawing_steps_generation_prompt()` |
| Story generation  | `story_prompts.py`            | `get_story_generation_prompt()`         |
| Step images       | `image_generation_prompts.py` | `get_step_image_*_prompt()`             |
