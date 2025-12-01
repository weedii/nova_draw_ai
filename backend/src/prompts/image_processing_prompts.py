"""
Image processing service prompts for Gemini and OpenAI APIs.

This module contains prompts used by the ImageProcessingService for:
- Voice prompt enhancement (GPT-3.5-turbo)
- Image processing with Gemini
"""

# Commented for now, cause not being used anywhere!
# def get_voice_prompt_enhancement_prompt(user_request: str, subject: str = None) -> str:
#     """
#     Get the prompt for enhancing voice input into a focused editing prompt.

#     This prompt is used with GPT-3.5-turbo to create short, preservation-focused
#     prompts that guide the AI toward vibrant, imaginative transformations.

#     Args:
#         user_request: Transcribed voice request (e.g., "put it in Paris")
#         subject: What the child drew (e.g., "dog", "cat") - from tutorial

#     Returns:
#         str: Enhancement prompt for OpenAI API
#     """

#     # Build context about what was drawn
#     subject_context = f"a {subject}" if subject else "their picture"

#     return f"""A child just drew {subject_context} and said: "{user_request}"

# Generate a prompt (5-7 sentences) for an image editing AI that will enhance the drawing into a vibrant, imaginative artwork.

# ⚠️ CRITICAL RULE - FOLLOW THE CHILD'S LINES EXACTLY, DON'T REDRAW ⚠️

# ABSOLUTE REQUIREMENTS:
# 1. You MUST follow exactly what the child asked for - do NOT make up your own ideas
# 2. TRACE the child's existing lines and shapes - follow their exact geometry
# 3. The child's original hand-drawn lines are the FOUNDATION - keep them visible
# 4. Think of this as "coloring and polishing" the drawing, not redrawing it
# 5. The result should look like an enhanced version of the original, NOT a completely new image
# 6. NEVER rotate or change the orientation of the drawing - keep it in the same orientation
# 7. A child must immediately recognize their own drawing in the result

# CRITICAL CONSTRAINT - FOLLOW THE LINES, DON'T CREATE NEW GEOMETRY:
# - TRACE the child's existing lines - follow their exact shape and curves
# - FOLLOW THE EXACT SAME SHAPES AND LINES OF THE ORIGINAL DRAWING - this is the most important rule
# - Match the original drawing's geometry precisely - don't improve or "fix" the shapes
# - NEVER go outside the boundaries of the original drawing - all enhancements must stay within the original shapes
# - NEVER extend or expand the drawing beyond its original outline
# - NEVER create a new, perfect geometric shape to replace the original
# - NEVER redraw the object with better proportions or symmetry
# - If the child drew an imperfect ball, enhance THAT imperfect ball - don't create a perfect sphere
# - If the child drew a wonky circle, keep the wonky shape and add colors to it
# - If the child's drawing is messy or unclear, STILL follow the messy lines - don't "fix" them into a clean shape
# - If the child drew rough/sketchy lines, keep those rough lines visible - enhance them, don't replace them
# - Keep the child's original drawing style and structure visible
# - Add details and modifications to the existing drawing, not replace it
# - IMPORTANT: When in doubt, preserve the original geometry exactly as drawn, even if it's imperfect

# CRITICAL CONSTRAINT - NO ROTATION:
# - NEVER rotate or flip the drawing horizontally or vertically
# - NEVER rotate the drawing even if asked to do so
# - Keep the drawing in the EXACT SAME ORIENTATION as the original
# - If the drawing is upside down in the original, keep it upside down
# - Only add enhancements, effects, and details - NO rotations or flips

# BACKGROUND REPLACEMENT:
# - ALWAYS replace the paper/white background with a contextual background
# - The background should match the context of the drawing (e.g., if drawing a dog, add outdoor scenery)
# - The new background should complement and enhance the drawing
# - Make the background colorful and fitting to the scene
# - The background should NOT compete with the main drawing - keep it subtle

# ENHANCEMENT RULES:
# - Keep the child's original drawing as the foundation - it's the most important element
# - TRACE the existing lines with colors, gradients, glows, and sparkles
# - Add small details and effects that don't obscure the original
# - Make it look polished and colorful (animated style, not photorealistic)
# - Include personality and energy - make it look alive and joyful
# - Always add a contextual, colorful background that complements the character
# - Keep it kid-friendly and full of wonder
# - Understand child language: "put in paris" = "place in Paris", "make alive" = "bring to life", "colorful" = "vibrant colors"

# IMPORTANT: Output ONLY the prompt text. No prefixes or labels.

# EXAMPLES:
# Child says "make cat chasing mouse" → "Enhance this child's cat by tracing its lines with vibrant colors and polishing it. Keep the cat's original shape, pose, and orientation exactly as drawn - follow the child's lines, don't redraw them. Add a cute little mouse nearby and motion lines to show action. Give the cat bright, expressive eyes. Add a simple colorful background with sparkles and magical effects. Make it look alive and joyful while keeping the child's original drawing clearly visible."

# Child says "put dog in paris" → "Enhance this child's dog by tracing its lines with vibrant colors and polishing. Keep the dog's original shape, pose, and orientation exactly as drawn - follow the child's lines, don't redraw them. Add the Eiffel Tower in the background with golden lights. Give the dog warm, colorful fur with gradients. Add pink and purple sunset clouds and sparkles. Make it look magical while the child's original drawing remains the clear focus."

# Child says "make flower rainbow" → "Enhance this child's flower by tracing its lines with beautiful rainbow colors on the petals. Keep the flower's original shape, structure, and orientation exactly as drawn - follow the child's lines, don't redraw them. Add sparkles and glows around the flower. Create a simple, colorful background. Make it look vibrant and magical while keeping the child's drawing clearly visible."

# Child says "make it a fighter jet" → "Enhance this child's airplane by tracing its lines and adding fighter jet details to it. Keep the airplane's original shape and orientation exactly as drawn - follow the child's lines, don't redraw them. Add sleek details, weapons, and military markings to make it look like a fighter jet. Give it vibrant metallic colors and glows. Add a dynamic background with clouds and effects. Make it look powerful and cool while the child's original airplane drawing remains clearly visible."

# Child says "make it colorful" → "Enhance this child's drawing by tracing its lines with vibrant, bold colors and polishing it. Keep the original drawing recognizable, in the same pose, and in the same orientation - follow the child's lines exactly, don't redraw them. Add gradients, glows, and sparkles throughout. Include a simple, colorful background. Make it look animated and full of personality while the child's original drawing remains clearly visible."

# Child says "make it a rainbow ball" → "Enhance this child's ball by tracing its lines with beautiful rainbow colors and stripes. Keep the ball's original shape and orientation exactly as drawn - follow the child's lines, don't create a perfect sphere. Add rainbow colors (red, orange, yellow, green, blue, purple) as stripes or swirls on the ball following its existing shape. Add sparkles and a glossy shine effect. Create a simple, colorful background. Make it look vibrant and magical while the child's original ball drawing remains clearly visible."
# """


def get_image_processing_prompt_en(edit_prompt: str, subject: str = None) -> str:
    """
    Get the prompt for processing an image with Gemini (English version).

    This prompt wraps the detailed edit instructions from the database with
    preservation guidelines to ensure the child's drawing remains recognizable
    while transforming it into a vibrant, imaginative artwork.

    Args:
        edit_prompt: The detailed editing instructions (from edit_options table)
        subject: What the child drew (e.g., 'dog', 'cat') - helps Gemini understand the drawing

    Returns:
        str: Full prompt for Gemini image processing
    """

    # Build context about what was drawn
    subject_context = f"The child drew a {subject}. " if subject else ""

    return f"""You are an artist enhancing a child's hand-drawn picture into a vibrant, stylized artwork for a kids' creativity app.

{subject_context}
⚠️ CRITICAL RULE - TRACE THE CHILD'S LINES, DON'T REDRAW THE OBJECT ⚠️

ABSOLUTE REQUIREMENTS (FAILURE TO FOLLOW = WRONG RESULT):
1. TRACE the child's existing lines and shapes - follow their exact geometry
2. The child's original hand-drawn lines are the FOUNDATION - keep them visible
3. You are COLORING and POLISHING the existing drawing - NOT redrawing it
4. The result must look like the original drawing with enhancements, NOT a new object
5. A child must immediately recognize their own drawing in the result

CRITICAL CONSTRAINT - FOLLOW THE LINES, DON'T CREATE NEW GEOMETRY:
- TRACE the child's existing lines - follow their exact shape and curves
- FOLLOW THE EXACT SAME SHAPES AND LINES OF THE ORIGINAL DRAWING - this is the most important rule
- Match the original drawing's geometry precisely - don't improve or "fix" the shapes
- NEVER go outside the boundaries of the original drawing - all enhancements must stay within the original shapes
- NEVER extend or expand the drawing beyond its original outline
- NEVER create a new, perfect geometric shape to replace the original
- NEVER redraw the object with better proportions or symmetry
- If the child drew an imperfect ball, folow its shapes and lines - don't create a perfect sphere
- If the child drew a wonky circle, keep the wonky shape and add colors to it
- If the child drew a simple stick figure, keep the simple stick figure - don't redraw it realistically
- If the child's drawing is messy or unclear, STILL follow the messy lines - don't "fix" them into a clean shape
- If the child drew rough/sketchy lines, keep those rough lines visible - enhance them, don't replace them
- Keep the child's original drawing style and structure visible
- Add details and modifications to the existing drawing, not replace it
- IMPORTANT: When in doubt, preserve the original geometry exactly as drawn, even if it's imperfect
- CRITICAL: Stay within the boundaries of the original drawing - do not go outside the lines

CRITICAL CONSTRAINT - PRESERVE ORIENTATION:
- NEVER rotate the drawing horizontally or vertically
- NEVER rotate or flip the drawing even if asked to do so
- Keep the drawing in the EXACT SAME ORIENTATION as the original
- If the airplane was drawn pointing right, keep it pointing right (don't rotate it)
- If the character was upright, keep it upright (don't tilt or rotate it)
- If the drawing is upside down in the original, keep it upside down
- Only add enhancements, effects, and details - NO rotations or flips

BACKGROUND REPLACEMENT:
- ALWAYS replace the paper/white background with a contextual background
- The background should match the context of the drawing (e.g., if drawing a dog, add outdoor scenery)
- The new background should complement and enhance the drawing
- Make the background colorful and fitting to the scene
- The background should NOT compete with the main drawing - keep it subtle

ENHANCEMENT APPROACH:
- Think of this as "coloring and polishing" the child's drawing, not redrawing it
- TRACE the existing lines with colors, details, and effects
- Add colors, details, and effects AROUND and WITHIN the existing lines
- Enhance what's already there, don't replace it
- Keep the child's drawing style visible (hand-drawn feel)

ARTISTIC ENHANCEMENTS (while preserving original):
- Add vibrant colors and gradients to existing shapes by tracing them
- Add atmospheric effects: glows, sparkles, light rays (subtle, not overwhelming)
- Include small dynamic elements that don't obscure the original
- Add depth with gentle shadows and layering
- Enhance the character's personality through expression and details
- Use smooth, polished rendering (digital art style, not realistic)
- Always add a contextual, colorful background that complements the character

YOUR TASK:
{edit_prompt}

IMPORTANT REMINDERS:
- The original drawing must be the foundation - everything else builds on it
- If the child drew a simple stick figure, it should still be recognizable as a stick figure (just enhanced)
- If the child drew a cat, it should still look like their cat (just more colorful and polished)
- If the child drew an airplane, it should still look like their airplane (just enhanced with fighter jet details)
- If the child drew an imperfect ball, it should still look like their imperfect ball (just with rainbow colors added)
- NEVER rotate or change the orientation of the drawing
- NEVER create a new, perfect version that hides the original
- Keep it kid-friendly, joyful, and full of wonder
- Add special effects and magical elements that enhance, not replace
- The child's hand-drawn lines must remain visible and be the foundation

TECHNICAL REQUIREMENTS:
- Return ONLY the edited image
- No text, watermarks, or labels
- Maintain high image quality
- The child's original drawing must be clearly visible and recognizable in the result
- The drawing must be in the EXACT SAME ORIENTATION as the original
- The original hand-drawn lines must be the visible foundation of the final artwork
"""


def get_image_processing_prompt_de(edit_prompt: str, subject: str = None) -> str:
    """
    Get the prompt for processing an image with Gemini (German version).

    This prompt wraps the detailed edit instructions from the database with
    preservation guidelines to ensure the child's drawing remains recognizable
    while transforming it into a vibrant, imaginative artwork.

    Args:
        edit_prompt: The detailed editing instructions (from edit_options table)
        subject: What the child drew (e.g., 'dog', 'cat') - helps Gemini understand the drawing

    Returns:
        str: Full prompt for Gemini image processing
    """

    # Build context about what was drawn
    subject_context = f"Das Kind hat ein {subject} gezeichnet. " if subject else ""

    return f"""Du bist ein Künstler, der die handgezeichnete Bild eines Kindes in ein lebendiges, stilisiertes Kunstwerk für eine Kreativitäts-App für Kinder verwandelst.

{subject_context}
⚠️ KRITISCHE REGEL - FOLGE DEN LINIEN DES KINDES, ZEICHNE DAS OBJEKT NICHT NEU ⚠️

ABSOLUTE ANFORDERUNGEN (NICHTBEACHTUNG = FALSCHES ERGEBNIS):
1. FOLGE den vorhandenen Linien und Formen des Kindes - behalte ihre genaue Geometrie bei
2. Die ursprünglichen handgezeichneten Linien des Kindes sind die GRUNDLAGE - halte sie sichtbar
3. Du FÄRBST und POLIERST die vorhandene Zeichnung - du zeichnest sie NICHT neu
4. Das Ergebnis muss wie die ursprüngliche Zeichnung mit Verbesserungen aussehen, NICHT wie ein neues Objekt
5. Ein Kind muss seine eigene Zeichnung sofort im Ergebnis erkennen

KRITISCHE EINSCHRÄNKUNG - FOLGE DEN LINIEN, ERSTELLE KEINE NEUE GEOMETRIE:
- FOLGE den vorhandenen Linien des Kindes - behalte ihre genaue Form und Kurven bei
- FOLGE DEN EXAKT GLEICHEN FORMEN UND LINIEN DER URSPRÜNGLICHEN ZEICHNUNG - das ist die wichtigste Regel
- Stimme die Geometrie der ursprünglichen Zeichnung genau ab - verbessere oder "repariere" die Formen nicht
- GEHE NIEMALS über die Grenzen der ursprünglichen Zeichnung hinaus - alle Verbesserungen müssen innerhalb der ursprünglichen Formen bleiben
- ERWEITERE oder VERGRÖSSERE die Zeichnung niemals über ihre ursprüngliche Kontur hinaus
- ERSTELLE niemals eine neue, perfekte geometrische Form als Ersatz für die ursprüngliche
- ZEICHNE das Objekt niemals mit besseren Proportionen oder Symmetrie neu
- Wenn das Kind einen unvollkommenen Ball gezeichnet hat, folge seinen Formen und Linien - erstelle keine perfekte Kugel
- Wenn das Kind einen schiefen Kreis gezeichnet hat, behalte die schiefe Form bei und füge Farben hinzu
- Wenn das Kind eine einfache Strichmännchen gezeichnet hat, behalte die einfache Strichmännchen - zeichne sie nicht realistisch neu
- Wenn die Zeichnung des Kindes unordentlich oder unklar ist, FOLGE trotzdem den unordentlichen Linien - "repariere" sie nicht in eine saubere Form
- Wenn das Kind raue/skizzenhafte Linien gezeichnet hat, halte diese rauen Linien sichtbar - verbessere sie, ersetze sie nicht
- Halte den ursprünglichen Zeichenstil und die Struktur des Kindes sichtbar
- Füge Details und Änderungen zur vorhandenen Zeichnung hinzu, nicht ersetze sie
- WICHTIG: Im Zweifelsfall bewahre die ursprüngliche Geometrie genau wie gezeichnet, auch wenn sie unvollkommen ist
- KRITISCH: Bleibe innerhalb der Grenzen der ursprünglichen Zeichnung - gehe nicht über die Linien hinaus

KRITISCHE EINSCHRÄNKUNG - BEHALTE DIE AUSRICHTUNG:
- DREHE die Zeichnung niemals horizontal oder vertikal
- DREHE oder SPIEGLE die Zeichnung niemals, auch wenn danach gefragt wird
- Halte die Zeichnung in der EXAKT GLEICHEN AUSRICHTUNG wie das Original
- Wenn das Flugzeug nach rechts gezeichnet wurde, halte es nach rechts gerichtet (drehe es nicht)
- Wenn die Figur aufrecht war, halte sie aufrecht (neige oder drehe sie nicht)
- Wenn die Zeichnung im Original kopfüber ist, halte sie kopfüber
- Füge nur Verbesserungen, Effekte und Details hinzu - KEINE Drehungen oder Spiegelungen

HINTERGRUND-ERSATZ:
- ERSETZE IMMER den Papier-/weißen Hintergrund durch einen kontextuellen Hintergrund
- Der Hintergrund sollte zum Kontext der Zeichnung passen (z. B. wenn ein Hund gezeichnet wird, füge Außenszenerie hinzu)
- Der neue Hintergrund sollte die Zeichnung ergänzen und verbessern
- Mache den Hintergrund farbenfroh und passend zur Szene
- Der Hintergrund sollte NICHT mit der Hauptzeichnung konkurrieren - halte ihn subtil

VERBESSERUNGSANSATZ:
- Denke daran, dass dies "Färben und Polieren" der Zeichnung des Kindes ist, nicht ein Neuzeichnen
- FOLGE den vorhandenen Linien mit Farben, Details und Effekten
- Füge Farben, Details und Effekte RUND UM und INNERHALB der vorhandenen Linien hinzu
- Verbessere das, was bereits vorhanden ist, ersetze es nicht
- Halte den Zeichenstil des Kindes sichtbar (handgezeichnetes Aussehen)

KÜNSTLERISCHE VERBESSERUNGEN (bei Bewahrung des Originals):
- Füge lebendige Farben und Farbverläufe zu vorhandenen Formen hinzu, indem du sie verfolgst
- Füge Atmosphäreneffekte hinzu: Glühen, Funkeln, Lichtstrahlen (subtil, nicht überwältigend)
- Beziehe kleine dynamische Elemente ein, die das Original nicht verdecken
- Füge Tiefe mit sanften Schatten und Schichtung hinzu
- Verbessere die Persönlichkeit der Figur durch Ausdruck und Details
- Verwende glatte, polierte Darstellung (digitale Kunststil, nicht realistisch)
- Füge immer einen kontextuellen, farbenfrohen Hintergrund hinzu, der die Figur ergänzt

DEINE AUFGABE:
{edit_prompt}

WICHTIGE ERINNERUNGEN:
- Die ursprüngliche Zeichnung muss die Grundlage sein - alles andere baut darauf auf
- Wenn das Kind eine einfache Strichmännchen gezeichnet hat, sollte sie immer noch als Strichmännchen erkennbar sein (nur verbessert)
- Wenn das Kind eine Katze gezeichnet hat, sollte sie immer noch wie ihre Katze aussehen (nur bunter und polierter)
- Wenn das Kind ein Flugzeug gezeichnet hat, sollte es immer noch wie ihr Flugzeug aussehen (nur mit verbesserten Kampfjet-Details)
- Wenn das Kind einen unvollkommenen Ball gezeichnet hat, sollte er immer noch wie ihr unvollkommener Ball aussehen (nur mit hinzugefügten Regenbogenfarben)
- DREHE oder ändere NIEMALS die Ausrichtung der Zeichnung
- ERSTELLE niemals eine neue, perfekte Version, die das Original verbirgt
- Halte es kinderfreundlich, freudig und voller Wunder
- Füge Spezialeffekte und magische Elemente hinzu, die verbessern, nicht ersetzen
- Die handgezeichneten Linien des Kindes müssen sichtbar bleiben und die Grundlage sein

TECHNISCHE ANFORDERUNGEN:
- Gebe NUR das bearbeitete Bild zurück
- Kein Text, Wasserzeichen oder Beschriftungen
- Behalte hohe Bildqualität bei
- Die ursprüngliche Zeichnung des Kindes muss im Ergebnis deutlich sichtbar und erkennbar sein
- Die Zeichnung muss in der EXAKT GLEICHEN AUSRICHTUNG wie das Original sein
- Die ursprünglichen handgezeichneten Linien müssen die sichtbare Grundlage des endgültigen Kunstwerks sein
"""
