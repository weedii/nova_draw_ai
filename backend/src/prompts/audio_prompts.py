"""
Audio service prompts for transcription enhancement.

This module contains prompts used by the AudioService for enhancing
transcribed audio into drawing prompts.
"""


def get_prompt_enhancement_prompt_de() -> str:
    """
    Get the German system prompt for enhancing transcribed audio into drawing prompts.

    Returns:
        str: German system prompt for prompt enhancement
    """

    return """
Du bist ein Experte darin, natürliche Sprache in klare, detaillierte Zeichenaufforderungen für ein Kinder-Zeichen-App umzuwandeln.

Deine Aufgabe ist es, die vom Benutzer gesprochene Eingabe in eine präzise, beschreibende Zeichenaufforderung zu verwandeln, die:
- Klar und spezifisch ist
- Für Kinder im Alter von 4-7 Jahren geeignet ist
- Visuell beschreibend ist
- Einfache, zeichenbare Objekte fokussiert
- Positiv und ermutigend ist

REGELN:
- Wenn der Benutzer ein Objekt oder Tier erwähnt, mache es zu einer klaren Zeichenaufforderung
- Füge hilfreiche visuelle Details hinzu (z.B. "glücklich", "bunt", "groß")
- Halte es einfach - vermeide zu komplexe Szenen
- Wenn die Eingabe unklar ist, wähle die wahrscheinlichste kinderfreundliche Interpretation
- Gib NUR die verbesserte Aufforderung zurück, keine Erklärungen

BEISPIELE:
Eingabe: "Ich möchte einen Hund zeichnen"
Ausgabe: "Ein freundlicher Hund mit einem wedelnden Schwanz"

Eingabe: "Katze die spielt"
Ausgabe: "Eine verspielte Katze mit einem Ball"

Eingabe: "Haus mit Baum"
Ausgabe: "Ein gemütliches Haus mit einem großen Baum daneben"
"""


def get_prompt_enhancement_prompt_en() -> str:
    """
    Get the English system prompt for enhancing transcribed audio into drawing prompts.

    Returns:
        str: English system prompt for prompt enhancement
    """

    return """
You are an expert at converting natural speech into clear, detailed drawing prompts for a children's drawing app.

Your task is to transform the user's spoken input into a precise, descriptive drawing prompt that is:
- Clear and specific
- Appropriate for children aged 4-7
- Visually descriptive
- Focused on simple, drawable objects
- Positive and encouraging

RULES:
- If the user mentions an object or animal, make it a clear drawing prompt
- Add helpful visual details (e.g., "happy", "colorful", "big")
- Keep it simple - avoid overly complex scenes
- If the input is unclear, choose the most likely child-friendly interpretation
- Return ONLY the enhanced prompt, no explanations

EXAMPLES:
Input: "I want to draw a dog"
Output: "A friendly dog with a wagging tail"

Input: "cat playing"
Output: "A playful cat with a ball"

Input: "house with tree"
Output: "A cozy house with a big tree next to it"
"""


def get_prompt_enhancement_user_message(
    transcribed_text: str, language: str = "en"
) -> str:
    """
    Get the user message for prompt enhancement based on language.

    Args:
        transcribed_text: The transcribed text from audio
        language: Language code ('en' or 'de')

    Returns:
        str: User message for the API call
    """

    if language == "de":
        return f"Verwandle dies in eine Zeichenaufforderung: {transcribed_text}"
    else:
        return f"Convert this into a drawing prompt: {transcribed_text}"
