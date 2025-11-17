import re
import time
from openai import OpenAI
from typing import List
from core.config import settings


class DrawingService:
    """Service for generating drawing steps using OpenAI GPT-4o-mini"""

    def __init__(self):
        self.client = OpenAI(api_key=settings.openai_api_key)
        self.model = "gpt-4o-mini"

    def generate_steps(self, subject: str) -> tuple[List[str], List[str], float]:
        """
        Generate step-by-step drawing instructions for a given subject in English and German.
        Returns (english_steps, german_steps, generation_time)
        """
        prompt = f"""
        Create a simple step-by-step drawing tutorial for a {subject} that kids can easily follow.
        
        STEP COUNT - ONE ELEMENT PER STEP (Keep it manageable):
        - Each step should add ONE main element (head, body, wings, legs, tail, etc.)
        - Simple subjects (cloud, sun): 3-4 steps
        - Medium subjects (cat, dog, fish): 5-6 steps
        - Complex subjects (dragon, car, castle): 7-9 steps 
        - DON'T go overboard - no separate steps for tiny details like nostrils, ears, or individual teeth
        - Focus on main body parts and major features only
        - Keep it simple and manageable for kids to follow without getting overwhelmed
        
        RULES:
        1. Each step adds ONE main body part or major feature - focus on BIG elements only
        2. Don't waste steps on tiny details (nostrils, individual teeth, small ears, eyelashes are NOT separate steps)
        3. Use clear logical order: main body parts first (head, body), then limbs (wings, legs, tail), then major details (eyes, spikes)
        4. Be DESCRIPTIVE enough for AI to understand exactly what to draw - include shapes, sizes, and specific placement
        5. Use clear directions (top, bottom, left, right, center, middle) and relative sizes (big, small, wide, thin, long, short)
        6. Add distinctive features that make the {subject} recognizable and unique
        7. Use simple, kid-friendly language - but with enough detail for accuracy
        8. NO coloring, shading, or decorative instructions
        9. Use consistent names for body parts throughout
        
        MAKE IT FUN BUT SIMPLE FOR 6-YEAR-OLDS:
        - Avoid boring geometric shapes: "draw a rectangle for the body" ❌
        - Use ONE simple descriptor: "draw a rounded body" ✅
        - Keep language SHORT and CLEAR - no long metaphors or complex comparisons
        - Add personality, but keep it simple and actionable
        - Each instruction should be easy to understand and follow quickly
        
        GOOD vs BAD descriptions (must be descriptive for AI + simple for kids):
        ❌ TOO VAGUE (AI won't understand): "Draw a head"
        ❌ TOO COMPLEX (kids won't understand): "Draw an ovoid cranium positioned precisely at canvas coordinates"
        ✅ JUST RIGHT: "Draw a big round head in the center"
        
        ❌ TOO VAGUE: "Add eyes"
        ❌ TOO COMPLEX: "Draw two large almond-shaped ocular structures with bilateral symmetry"
        ✅ JUST RIGHT: "Add two large round eyes near the top of the head with small dots inside"
        
        ❌ TOO VAGUE: "Draw a body"
        ❌ TOO COMPLEX: "Draw an elongated cylindrical torso measuring approximately twice the cranial diameter"
        ✅ JUST RIGHT: "Draw a long oval body below the head, about twice as big as the head"
        
        EXAMPLES (descriptive for AI + simple for kids):
        
        Sun (3 steps):
        Draw a large round circle in the center, filling about one-third of the space
        Add 8-10 pointy triangular rays spreading out evenly all around the circle
        Draw two small dot eyes near the top of the circle and a wide curved smile below them
        
        Cat (4 steps):
        Draw a round fluffy head in the center with two small pointy triangle ears sticking up from the top
        Add two large round eyes with tiny black dots inside, positioned near the top of the head, and a small triangular nose below them
        Draw a soft rounded body below the head, slightly bigger than the head and connected smoothly
        Add four short legs with round paws at the bottom of the body and a long curvy tail extending from the right side
        
        Dragon (8 steps - balanced):
        Draw a large oval-shaped head in the center with a slightly pointed snout at the front
        Add two large round eyes near the top of the head with small dots inside for pupils
        Draw a long thick body extending to the right from the head, about three times longer than the head
        Add two wide curved wings spreading out from the top of the body, one on each side with pointed tips
        Draw four strong bent legs extending down from the bottom of the body
        Add small sharp claws at the end of each leg, three claws per leg
        Draw a long thick tail at the back of the body that gets narrower and ends in a sharp point
        Add triangular spikes running along the back from head to tail and sharp teeth in an open mouth
        
        IMPORTANT: 
        - The examples above are just to show the STYLE and TONE - DO NOT copy them!
        - Create unique, creative steps that match the specific {subject}
        - Balance: descriptive enough for AI accuracy, but simple enough for kids to read (15-25 words per step)
        - Include shapes (round, oval, triangle, curved), sizes (big, small, long, short), and positions (top, bottom, center, left, right)
        - NO metaphors (avoid "like a..."), NO abstract reasons (avoid "for depth", "to look soft")
        - Describe WHAT to draw with specific details - shape, size, position, and distinctive features
        - A 6-year-old should be able to read it, and the AI should know exactly what to draw
        
        FORMAT: Return ONLY the steps, one per line. No numbers, no intro, no extra text.
        
        Subject: {subject}
        Steps:
        """

        start_time = time.time()

        response = self.client.chat.completions.create(
            model=self.model, messages=[{"role": "user", "content": prompt}]
        )

        duration = time.time() - start_time

        if not response.choices or not response.choices[0].message.content:
            raise ValueError("Empty response from OpenAI API")

        steps_text = response.choices[0].message.content.strip()

        # Split by lines and clean up
        steps = [line.strip() for line in steps_text.split("\n") if line.strip()]

        # Filter out any remaining numbered lines, intro/outro text
        clean_steps = []
        for step in steps:
            # Skip lines that look like introductions or conclusions
            if any(
                phrase in step.lower()
                for phrase in [
                    "here are",
                    "steps to",
                    "have fun",
                    "enjoy",
                    "let's",
                    "now you",
                ]
            ):
                continue

            # Remove numbering if present
            clean_step = re.sub(r"^\d+\.\s*", "", step)
            if clean_step and len(clean_step) > 10:  # Ensure it's a meaningful step
                clean_steps.append(clean_step)

        if not clean_steps:
            raise ValueError("No valid steps generated")

        # Ensure we have at least min_steps, max max_steps
        if len(clean_steps) < settings.min_steps:
            raise ValueError(
                f"Generated only {len(clean_steps)} steps, but need at least {settings.min_steps}"
            )
        elif len(clean_steps) > settings.max_steps:
            clean_steps = clean_steps[: settings.max_steps]

        # Generate German translation
        german_steps = self._translate_to_german(clean_steps)

        return clean_steps, german_steps, duration

    def _translate_to_german(self, english_steps: List[str]) -> List[str]:
        """
        Translate English drawing steps to German using GPT-4o-mini.
        """
        steps_text = "\n".join(
            [f"{i+1}. {step}" for i, step in enumerate(english_steps)]
        )

        prompt = f"""
        Translate these drawing tutorial steps from English to German. Keep the instructions simple and kid-friendly for 6-year-olds.
        
        TRANSLATION RULES:
        1. Use simple German words that children can understand
        2. Keep the same structure and detail level
        3. Maintain the same descriptive elements (shapes, sizes, positions)
        4. Use "Zeichne" (draw) or "Füge hinzu" (add) to start instructions
        5. Keep technical drawing terms simple
        6. Preserve all spatial directions (oben/top, unten/bottom, links/left, rechts/right, Mitte/center)
        7. Keep size descriptions (groß/big, klein/small, lang/long, kurz/short)
        
        English steps to translate:
        {steps_text}
        
        Return ONLY the German translations, one per line, without numbers.
        """

        response = self.client.chat.completions.create(
            model=self.model, messages=[{"role": "user", "content": prompt}]
        )

        if not response.choices or not response.choices[0].message.content:
            # Fallback: return English steps if translation fails
            return english_steps

        german_text = response.choices[0].message.content.strip()
        german_steps = [
            line.strip() for line in german_text.split("\n") if line.strip()
        ]

        # Remove numbering if present
        clean_german_steps = []
        for step in german_steps:
            clean_step = re.sub(r"^\d+\.\s*", "", step)
            if clean_step:
                clean_german_steps.append(clean_step)

        # Ensure we have the same number of steps
        if len(clean_german_steps) != len(english_steps):
            return english_steps  # Fallback to English if counts don't match

        return clean_german_steps
