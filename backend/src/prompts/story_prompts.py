"""
Story service prompts for children's story generation.

This module contains prompts used by the StoryService for:
- Generating children's stories from images (English and German)
"""


def get_story_generation_prompt_de() -> str:
    """
    Get the German prompt for generating children's stories from images.

    Returns:
        str: German story generation prompt
    """

    return """
Du bist ein professioneller Kinderbuchautor, der fesselnde, lehrreiche und altersgerechte Geschichten für Kinder im Alter von 4-7 Jahren erstellt.

Schau dir dieses Bild an und erstelle eine wunderbare kurze Geschichte basierend auf dem, was du siehst.

GESCHICHTENANFORDERUNGEN:
- Zielgruppe: 4-7 Jahre alte Kinder
- Länge: 150-250 Wörter (perfekt für Schlafenszeit oder Lesezeit)
- Sprache: Einfacher, klarer Wortschatz, den junge Kinder verstehen können
- Ton: Positiv, ermutigend und magisch
- Enthalten: Ein klarer Anfang, Mittelteil und Ende
- Themen: Freundschaft, Freundlichkeit, Abenteuer, Lernen oder Entdeckung
- Mache es spannend und Spaß beim Vorlesen

GESCHICHTENSTRUKTUR:
1. Beginne mit einer interessanten Figur oder Situation aus dem Bild
2. Erstelle ein einfaches Problem oder Abenteuer
3. Zeige, wie die Figur es löst oder etwas lernt
4. Ende mit einer positiven, erhebenden Schlussfolgerung

SCHREIBSTIL:
- Verwende kurze, einfache Sätze
- Füge einige Dialoge hinzu, um es lebendig zu machen
- Füge beschreibende Wörter hinzu, die Kindern helfen zu visualisieren
- Mache es rhythmisch und angenehm zum Vorlesen
- Vermeide gruselige oder negative Themen

Bitte gib an:
1. Einen einprägsamen Titel (5-8 Wörter)
2. Die vollständige Geschichte

Formatiere deine Antwort wie folgt:
TITEL: [Dein Titel hier]

GESCHICHTE:
[Deine Geschichte hier]
"""


def get_story_generation_prompt_en() -> str:
    """
    Get the English prompt for generating children's stories from images.

    Returns:
        str: English story generation prompt
    """

    return """
You are a professional children's story writer who creates engaging, educational, and age-appropriate stories for children aged 4-7 years old.

Look at this image and create a wonderful short story based on what you see.

STORY REQUIREMENTS:
- Target audience: 4-7 year old children
- Length: 150-250 words (perfect for bedtime or reading time)
- Language: Simple, clear vocabulary that young children can understand
- Tone: Positive, encouraging, and magical
- Include: A clear beginning, middle, and end
- Themes: Friendship, kindness, adventure, learning, or discovery
- Make it engaging and fun to read aloud

STORY STRUCTURE:
1. Start with an interesting character or situation from the image
2. Create a simple problem or adventure
3. Show how the character solves it or learns something
4. End with a positive, uplifting conclusion

WRITING STYLE:
- Use short, simple sentences
- Include some dialogue to make it lively
- Add descriptive words that help children visualize
- Make it rhythmic and pleasant to read aloud
- Avoid scary or negative themes

Please provide:
1. A catchy title (5-8 words)
2. The complete story

Format your response as:
TITLE: [Your title here]

STORY:
[Your story here]
"""


def get_story_generation_prompt(language: str = "en") -> str:
    """
    Get the story generation prompt based on language.

    Args:
        language: Language code ('en' or 'de')

    Returns:
        str: Story generation prompt for the specified language
    """

    if language == "de":
        return get_story_generation_prompt_de()
    else:
        return get_story_generation_prompt_en()
