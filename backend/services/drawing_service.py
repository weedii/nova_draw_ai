import re
import time
from openai import OpenAI
from typing import List
from config import settings


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
        You are creating a step-by-step drawing tutorial for kids aged 4-7 to learn how to draw a {subject}.
        
        CRITICAL CONTEXT:
        - These steps will be used by an AI image generator to create visual step-by-step images
        - Kids will look at the images and copy them on their paper
        - Each step MUST build logically on the previous step
        - This is like a drawing book where each page shows one more element added
        
        STEP COUNT (Keep it manageable for young kids):
        - Simple subjects (sun, cloud, balloon): 3-4 steps
        - Medium subjects (fish, cat, dog, tree): 5-6 steps
        - Complex subjects (dragon, car, castle, dinosaur): 7-9 steps
        - Focus on MAIN shapes and features only - no tiny details
        
        LOGICAL DRAWING ORDER (Think like an artist teaching kids):
        - FISH/SEA CREATURES: Body (main oval) → Tail → Fins → Head/Face → Eye
        - BIRDS: Body (round) → Head → Wings → Tail → Legs → Beak/Eyes
        - LAND ANIMALS (cat, dog, lion): Head → Body → Legs → Tail → Face details
        - INSECTS: Body segments → Wings → Legs → Head/Antennae → Eyes
        - OBJECTS (car, house): Main structure → Major parts → Windows/Doors → Details
        - FANTASY (dragon, unicorn): Head → Body → Wings/Horn → Legs → Tail → Special features
        
        RULES FOR EACH STEP (CRITICAL - AI needs to understand exactly what to draw):
        1. Add ONE main element per step (body, head, wings, tail, legs, etc.)
        2. NO tiny details as separate steps (nostrils, eyelashes, individual teeth)
        3. Be EXTREMELY DESCRIPTIVE - these instructions go to an AI image generator:
           - SHAPE: Always specify the shape (oval, round, curved, triangular, etc.)
           - SIZE: Always include size (big, small, long, short, wide, thin)
           - POSITION: Always tell WHERE exactly (center, top, bottom, left side, right end)
           - CONNECTION: Always say HOW it connects (attached to, extends from, below, above)
           - ORIENTATION: Specify direction (pointing left, facing forward, tilted right, lying sideways)
        4. Use clear spatial relationships: "at the right end of the body", "below the head", "on top of the body"
        5. Use size comparisons: "twice as big as the head", "half the size of the body", "about the same width"
        6. Include visual details: "with a pointed tip", "spreading out wide", "curving upward"
        7. Make each step simple enough for a 4-7 year old to read BUT detailed enough for AI to draw correctly
        8. NO coloring or shading instructions - only shapes, lines, and positions
        9. Keep the same names for body parts throughout all steps
        
        HOW TO WRITE EACH STEP (MUST include all details for AI):
        
        ❌ BAD STEP (Too vague): "Draw a body"
        - AI doesn't know: What shape? How big? Where? What orientation?
        
        ❌ BAD STEP (Not descriptive enough): "Add a tail"
        - AI doesn't know: What shape tail? Where? How big? What direction?
        
        ✅ GOOD STEP (Perfect for AI): "Draw a big oval body in the center, lying sideways with the wider end on the left"
        - Shape: oval ✓
        - Size: big ✓
        - Position: center ✓
        - Orientation: lying sideways ✓
        - Detail: wider end on left ✓
        
        ✅ GOOD STEP (Perfect for AI): "Add a curved triangular tail at the right end of the body, spreading out wide with a pointed tip"
        - Shape: curved triangular ✓
        - Position: right end of body ✓
        - Connection: at the body ✓
        - Size: spreading out wide ✓
        - Detail: pointed tip ✓
        
        ✅ GOOD STEP (Perfect for AI): "Draw two curved fins on the top of the body near the middle, pointing upward and slightly backward"
        - Shape: curved ✓
        - Position: top of body, near middle ✓
        - Quantity: two ✓
        - Direction: pointing upward and slightly backward ✓
        
        EXAMPLE - FISH (Super descriptive for AI, simple for kids):
        Step 1: Draw a big oval body in the center, lying sideways with the wider part on the left side
        Step 2: Add a wide curved tail at the right end of the body, spreading out in a fan shape with a slight curve
        Step 3: Draw two small curved fins - one on top of the body near the middle pointing upward, and one on the bottom pointing downward
        Step 4: Add a large round eye near the front left side of the body with a tiny black dot in the center
        Step 5: Draw a small curved smile line at the very front left for the mouth, and add 3-4 curved lines across the body for scales
        
        EXAMPLE - CAT (Super descriptive for AI, simple for kids):
        Step 1: Draw a big round head in the center with two small pointy triangle ears standing up on the top
        Step 2: Add two large round eyes near the top of the head with tiny dots inside for pupils, and a small upside-down triangle nose below them in the center
        Step 3: Draw a soft rounded body below the head, about twice as big as the head, connected smoothly at the bottom of the head
        Step 4: Add four short curved legs at the bottom of the body with small round paws, and a long curvy tail extending from the right side of the body
        Step 5: Draw three long thin whiskers on each side of the face spreading outward, and a small curved smile below the nose
        
        EXAMPLE - DRAGON (Super descriptive for AI, simple for kids):
        Step 1: Draw a large oval head in the center with a slightly pointed snout extending forward on the left side
        Step 2: Add two big round eyes near the top of the head with small dots for pupils, and draw a curved smiling mouth across the snout
        Step 3: Draw a long thick body extending to the right from the back of the head, about three times longer than the head
        Step 4: Add two large curved wings spreading out from the top of the body, one on each side with pointed tips curving upward
        Step 5: Draw four strong bent legs extending down from the bottom of the body, with small curved claws at the end of each leg
        Step 6: Add a long thick tail at the back right of the body, curving downward and getting thinner toward the pointed tip
        Step 7: Draw triangular spikes running along the back from the head to the tail, and add two small curved horns on top of the head
        
        IMPORTANT REQUIREMENTS FOR EVERY STEP:
        - The examples above show the LEVEL OF DETAIL needed - follow this style!
        - Create unique steps for the specific {subject} you're given
        - EVERY STEP MUST INCLUDE:
          * SHAPE: What shape is it? (oval, round, curved, triangular, rectangular, etc.)
          * SIZE: How big? (big, small, long, short, wide, thin, twice as big, half the size)
          * POSITION: Where exactly? (center, top, bottom, left side, right end, near the middle)
          * CONNECTION: How does it attach? (extending from, attached to, below, above, at the end of)
          * DIRECTION/ORIENTATION: Which way? (pointing up, facing left, curving downward, spreading out)
        - Use concrete descriptive words - NO metaphors unless super simple ("like a football")
        - The AI image generator needs these details to know EXACTLY what to draw and where!
        - A 5-year-old should understand the words, but an AI should have enough info to draw it perfectly
        
        FORMAT: Return ONLY the steps, one per line. No numbers, no intro, no extra text.
        
        Subject: {subject}
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
