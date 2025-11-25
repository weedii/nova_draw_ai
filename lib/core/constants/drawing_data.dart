import 'package:flutter/material.dart';
import 'colors.dart';

class EditOption {
  final String id;
  final String titleEn;
  final String titleDe;
  final String descriptionEn;
  final String descriptionDe;
  final String promptEn; // Detailed AI prompt in English
  final String promptDe; // Detailed AI prompt in German
  final String emoji;
  final Color color;

  const EditOption({
    required this.id,
    required this.titleEn,
    required this.titleDe,
    required this.descriptionEn,
    required this.descriptionDe,
    required this.promptEn,
    required this.promptDe,
    required this.emoji,
    required this.color,
  });
}

class DrawingStep {
  final String stepEn;
  final String stepDe;
  final String stepImg; // Image URL (public URL or link)

  const DrawingStep({
    required this.stepEn,
    required this.stepDe,
    required this.stepImg,
  });
}

class Drawing {
  final String id;
  final String nameEn;
  final String nameDe;
  final String emoji;
  final List<DrawingStep> steps;
  final List<EditOption> editOptions;

  const Drawing({
    required this.id,
    required this.nameEn,
    required this.nameDe,
    required this.emoji,
    required this.steps,
    this.editOptions = const [],
  });
}

class DrawingCategory {
  final String id;
  final String titleEn;
  final String titleDe;
  final String descriptionEn;
  final String descriptionDe;
  final String icon;
  final Color color;
  final List<Drawing> drawings;

  const DrawingCategory({
    required this.id,
    required this.titleEn,
    required this.titleDe,
    required this.descriptionEn,
    required this.descriptionDe,
    required this.icon,
    required this.color,
    required this.drawings,
  });
}

class DrawingData {
  static const List<DrawingCategory> categories = [
    // Animals Category
    DrawingCategory(
      id: 'animals',
      titleEn: 'Animals',
      titleDe: 'Tiere',
      descriptionEn: 'Draw cute animals like dogs, cats, and more!',
      descriptionDe: 'Zeichne süße Tiere wie Hunde, Katzen und mehr!',
      icon: '🐶',
      color: AppColors.primary,
      drawings: [
        Drawing(
          id: 'dog',
          nameEn: 'Dog',
          nameDe: 'Hund',
          emoji: '🐕',
          steps: [
            DrawingStep(
              stepEn: 'Draw a circle for the head',
              stepDe: 'Zeichne einen Kreis für den Kopf',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add floppy ears on both sides',
              stepDe: 'Füge schlappende Ohren an beiden Seiten hinzu',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Draw an oval body below the head',
              stepDe: 'Zeichne einen ovalen Körper unter den Kopf',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add four legs and a wagging tail',
              stepDe: 'Füge vier Beine und einen wedelnden Schwanz hinzu',
              stepImg: '', // Will be populated from API
            ),
          ],
          editOptions: [
            EditOption(
              id: 'make_alive',
              titleEn: 'Make it Alive',
              titleDe: 'Zum Leben erwecken',
              descriptionEn: 'Add movement and energy to your dog!',
              descriptionDe: 'Füge Bewegung und Energie zu deinem Hund hinzu!',
              promptEn:
                  'Transform this child\'s dog drawing into a lively, energetic cartoon dog with bright eyes, a wagging tail, and playful expression. Add vibrant colors, smooth lines, and make it look animated and full of life. Keep the original drawing style recognizable but enhance it to look more dynamic and cheerful.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Hundes in einen lebendigen, energiegeladenen Cartoon-Hund mit strahlenden Augen, wedelndem Schwanz und verspieltem Ausdruck. Füge lebendige Farben, glatte Linien hinzu und lass ihn animiert und voller Leben aussehen. Behalte den ursprünglichen Zeichenstil erkennbar bei, aber verbessere ihn, um dynamischer und fröhlicher auszusehen.',
              emoji: '⚡',
              color: AppColors.accent,
            ),
            EditOption(
              id: 'add_colors',
              titleEn: 'Make it Colorful',
              titleDe: 'Bunt machen',
              descriptionEn: 'Add beautiful colors and patterns!',
              descriptionDe: 'Füge schöne Farben und Muster hinzu!',
              promptEn:
                  'Add beautiful, vibrant colors to this child\'s dog drawing. Use a rainbow of bright, cheerful colors like orange, yellow, pink, blue, and purple. Add fun patterns like spots, stripes, or swirls to make it look magical and colorful. Keep the drawing style child-friendly and maintain the original shapes.',
              promptDe:
                  'Füge dieser Kinderzeichnung eines Hundes schöne, lebendige Farben hinzu. Verwende eine Regenbogenpalette aus hellen, fröhlichen Farben wie Orange, Gelb, Rosa, Blau und Lila. Füge lustige Muster wie Punkte, Streifen oder Wirbel hinzu, um es magisch und farbenfroh aussehen zu lassen. Behalte den kinderfreundlichen Zeichenstil bei und erhalte die ursprünglichen Formen.',
              emoji: '🌈',
              color: AppColors.primary,
            ),
            EditOption(
              id: 'add_accessories',
              titleEn: 'Add Accessories',
              titleDe: 'Accessoires hinzufügen',
              descriptionEn: 'Give your dog a collar, hat, or toy!',
              descriptionDe:
                  'Gib deinem Hund ein Halsband, Hut oder Spielzeug!',
              promptEn:
                  'Add fun accessories to this child\'s dog drawing. Include items like a colorful collar with a tag, a cute hat or bow, a ball or toy nearby, and maybe a bone. Make the accessories bright, cheerful, and child-friendly. Keep the original drawing recognizable while making it more detailed and fun.',
              promptDe:
                  'Füge dieser Kinderzeichnung eines Hundes lustige Accessoires hinzu. Füge Elemente wie ein buntes Halsband mit Marke, einen süßen Hut oder eine Schleife, einen Ball oder ein Spielzeug in der Nähe und vielleicht einen Knochen hinzu. Mache die Accessoires hell, fröhlich und kinderfreundlich. Behalte die ursprüngliche Zeichnung erkennbar bei, während du sie detaillierter und lustiger machst.',
              emoji: '🎾',
              color: AppColors.secondary,
            ),
            EditOption(
              id: 'cartoon_style',
              titleEn: 'Cartoon Style',
              titleDe: 'Cartoon-Stil',
              descriptionEn: 'Transform into a cute cartoon character!',
              descriptionDe: 'Verwandle in einen süßen Cartoon-Charakter!',
              promptEn:
                  'Transform this child\'s dog drawing into a professional cartoon character style. Make it look like a character from a children\'s animated show with big expressive eyes, smooth rounded shapes, bold outlines, and vibrant colors. Add shading and highlights to give it depth while keeping it cute and child-friendly.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Hundes in einen professionellen Cartoon-Charakter-Stil. Lass ihn wie eine Figur aus einer Kinderanimationsserie aussehen mit großen ausdrucksstarken Augen, glatten abgerundeten Formen, kräftigen Umrissen und lebendigen Farben. Füge Schattierungen und Highlights hinzu, um ihm Tiefe zu verleihen, während du ihn süß und kinderfreundlich hältst.',
              emoji: '🎨',
              color: AppColors.success,
            ),
          ],
        ),
        Drawing(
          id: 'cat',
          nameEn: 'Cat',
          nameDe: 'Katze',
          emoji: '🐱',
          steps: [
            DrawingStep(
              stepEn: 'Draw a circle for the head',
              stepDe: 'Zeichne einen Kreis für den Kopf',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add pointy triangle ears on top',
              stepDe: 'Füge spitze Dreiecksohren oben hinzu',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Draw an oval body',
              stepDe: 'Zeichne einen ovalen Körper',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add eyes, nose, mouth, and whiskers',
              stepDe: 'Füge Augen, Nase, Mund und Schnurrhaare hinzu',
              stepImg: '', // Will be populated from API
            ),
          ],
          editOptions: [
            EditOption(
              id: 'fluffy_fur',
              titleEn: 'Make it Fluffy',
              titleDe: 'Flauschig machen',
              descriptionEn: 'Add soft, fluffy fur texture!',
              descriptionDe: 'Füge weiche, flauschige Fell-Textur hinzu!',
              promptEn:
                  'Transform this child\'s cat drawing into a fluffy, soft-looking cat with detailed fur texture. Add soft, fuzzy edges and make the fur look thick and cuddly. Use light and shadow to create depth in the fur. Keep it cute and child-friendly with warm colors.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Katze in eine flauschige, weich aussehende Katze mit detaillierter Fell-Textur. Füge weiche, flauschige Kanten hinzu und lass das Fell dick und kuschelig aussehen. Verwende Licht und Schatten, um Tiefe im Fell zu erzeugen. Halte es süß und kinderfreundlich mit warmen Farben.',
              emoji: '🐾',
              color: AppColors.accent,
            ),
            EditOption(
              id: 'magical_eyes',
              titleEn: 'Magical Eyes',
              titleDe: 'Magische Augen',
              descriptionEn: 'Give your cat sparkling magical eyes!',
              descriptionDe: 'Gib deiner Katze funkelnde magische Augen!',
              promptEn:
                  'Enhance this child\'s cat drawing by giving it large, sparkling, magical eyes that shine and glow. Add star sparkles, light reflections, and a magical glow around the eyes. Make the eyes expressive and enchanting with bright colors like blue, purple, or green. Keep the rest of the drawing recognizable.',
              promptDe:
                  'Verbessere diese Kinderzeichnung einer Katze, indem du ihr große, funkelnde, magische Augen gibst, die leuchten und glühen. Füge Sternen-Glitzer, Lichtreflexionen und ein magisches Leuchten um die Augen hinzu. Mache die Augen ausdrucksstark und bezaubernd mit hellen Farben wie Blau, Lila oder Grün. Halte den Rest der Zeichnung erkennbar.',
              emoji: '✨',
              color: AppColors.primary,
            ),
            EditOption(
              id: 'rainbow_colors',
              titleEn: 'Rainbow Cat',
              titleDe: 'Regenbogen-Katze',
              descriptionEn: 'Transform into a colorful rainbow cat!',
              descriptionDe: 'Verwandle in eine bunte Regenbogen-Katze!',
              promptEn:
                  'Transform this child\'s cat drawing into a magical rainbow cat with vibrant rainbow colors flowing through its fur. Use red, orange, yellow, green, blue, and purple in beautiful gradients. Add sparkles and a magical, dreamy atmosphere. Make it look fantastical while keeping the original cat shape.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Katze in eine magische Regenbogen-Katze mit lebendigen Regenbogenfarben, die durch ihr Fell fließen. Verwende Rot, Orange, Gelb, Grün, Blau und Lila in schönen Verläufen. Füge Glitzer und eine magische, verträumte Atmosphäre hinzu. Lass es fantastisch aussehen, während du die ursprüngliche Katzenform beibehältst.',
              emoji: '🌈',
              color: AppColors.success,
            ),
            EditOption(
              id: 'royal_cat',
              titleEn: 'Royal Cat',
              titleDe: 'Königliche Katze',
              descriptionEn: 'Add a crown and royal accessories!',
              descriptionDe:
                  'Füge eine Krone und königliche Accessoires hinzu!',
              promptEn:
                  'Transform this child\'s cat drawing into a royal, majestic cat. Add a golden crown on its head, a royal cape or collar with jewels, and maybe a throne or royal cushion. Use rich colors like gold, purple, and red. Make the cat look elegant and regal while keeping it cute and child-friendly.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Katze in eine königliche, majestätische Katze. Füge eine goldene Krone auf ihrem Kopf, einen königlichen Umhang oder Kragen mit Juwelen und vielleicht einen Thron oder ein königliches Kissen hinzu. Verwende reiche Farben wie Gold, Lila und Rot. Lass die Katze elegant und königlich aussehen, während du sie süß und kinderfreundlich hältst.',
              emoji: '👑',
              color: AppColors.secondary,
            ),
          ],
        ),
        Drawing(
          id: 'fish',
          nameEn: 'Fish',
          nameDe: 'Fisch',
          emoji: '🐠',
          steps: [
            DrawingStep(
              stepEn: 'Draw an oval for the fish body',
              stepDe: 'Zeichne ein Oval für den Fischkörper',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add a triangle tail and top fin',
              stepDe: 'Füge einen Dreiecksschwanz und eine obere Flosse hinzu',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add side fins and a big round eye',
              stepDe: 'Füge Seitenflossen und ein großes rundes Auge hinzu',
              stepImg: '', // Will be populated from API
            ),
          ],
          editOptions: [
            EditOption(
              id: 'underwater_scene',
              titleEn: 'Underwater Scene',
              titleDe: 'Unterwasser-Szene',
              descriptionEn: 'Add bubbles, coral, and sea plants!',
              descriptionDe: 'Füge Blasen, Korallen und Seepflanzen hinzu!',
              promptEn:
                  'Enhance this child\'s fish drawing by adding a beautiful underwater scene around it. Include colorful bubbles floating up, coral reefs, seaweed, sea plants, and maybe small fish friends. Use blue and green tones for the water. Make it look like a vibrant ocean environment while keeping the original fish as the main focus.',
              promptDe:
                  'Verbessere diese Kinderzeichnung eines Fisches, indem du eine schöne Unterwasserszene darum herum hinzufügst. Füge bunte Blasen hinzu, die nach oben schweben, Korallenriffe, Seetang, Seepflanzen und vielleicht kleine Fischfreunde. Verwende Blau- und Grüntöne für das Wasser. Lass es wie eine lebendige Ozeanumgebung aussehen, während du den ursprünglichen Fisch als Hauptfokus beibehältst.',
              emoji: '🫧',
              color: AppColors.primary,
            ),
            EditOption(
              id: 'tropical_fish',
              titleEn: 'Tropical Colors',
              titleDe: 'Tropische Farben',
              descriptionEn: 'Make it a colorful tropical fish!',
              descriptionDe: 'Mach es zu einem bunten tropischen Fisch!',
              promptEn:
                  'Transform this child\'s fish drawing into a vibrant tropical fish with bright, exotic colors. Use orange, yellow, blue, pink, and turquoise. Add beautiful patterns like stripes, spots, or scales. Make it look like a fish from a tropical coral reef with vivid, eye-catching colors.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Fisches in einen lebendigen tropischen Fisch mit hellen, exotischen Farben. Verwende Orange, Gelb, Blau, Rosa und Türkis. Füge schöne Muster wie Streifen, Punkte oder Schuppen hinzu. Lass ihn wie einen Fisch aus einem tropischen Korallenriff mit lebendigen, auffälligen Farben aussehen.',
              emoji: '🌺',
              color: AppColors.accent,
            ),
            EditOption(
              id: 'glowing_fish',
              titleEn: 'Glowing Fish',
              titleDe: 'Leuchtender Fisch',
              descriptionEn: 'Add magical glowing effects!',
              descriptionDe: 'Füge magische Leuchteffekte hinzu!',
              promptEn:
                  'Transform this child\'s fish drawing into a magical glowing fish that emits light. Add bioluminescent effects with glowing edges, sparkles, and light rays. Use neon colors like electric blue, bright green, or glowing purple. Make it look like a deep-sea creature that glows in the dark.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Fisches in einen magischen leuchtenden Fisch, der Licht ausstrahlt. Füge biolumineszente Effekte mit leuchtenden Kanten, Glitzer und Lichtstrahlen hinzu. Verwende Neonfarben wie elektrisches Blau, helles Grün oder leuchtendes Lila. Lass ihn wie eine Tiefseekreatur aussehen, die im Dunkeln leuchtet.',
              emoji: '🌟',
              color: AppColors.success,
            ),
          ],
        ),
        Drawing(
          id: 'elephant',
          nameEn: 'Elephant',
          nameDe: 'Elefant',
          emoji: '🐘',
          steps: [
            DrawingStep(
              stepEn: 'Draw a large circle for the head',
              stepDe: 'Zeichne einen großen Kreis für den Kopf',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add a long curved trunk hanging down',
              stepDe: 'Füge einen langen gebogenen Rüssel hinzu',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Draw a big oval body behind the head',
              stepDe: 'Zeichne einen großen ovalen Körper hinter den Kopf',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add four thick legs and big floppy ears',
              stepDe: 'Füge vier dicke Beine und große schlappende Ohren hinzu',
              stepImg: '', // Will be populated from API
            ),
          ],
          editOptions: [
            EditOption(
              id: 'circus_elephant',
              titleEn: 'Circus Elephant',
              titleDe: 'Zirkus-Elefant',
              descriptionEn: 'Add a colorful circus costume and hat!',
              descriptionDe: 'Füge ein buntes Zirkuskostüm und Hut hinzu!',
              promptEn:
                  'Transform this child\'s elephant drawing into a circus elephant performer. Add a decorative circus hat or headpiece, a colorful blanket or costume with patterns and tassels, and maybe a circus ball or platform. Use bright circus colors like red, yellow, and blue. Make it look festive and fun.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Elefanten in einen Zirkus-Elefanten-Darsteller. Füge einen dekorativen Zirkushut oder Kopfschmuck, eine bunte Decke oder ein Kostüm mit Mustern und Quasten und vielleicht einen Zirkusball oder eine Plattform hinzu. Verwende helle Zirkusfarben wie Rot, Gelb und Blau. Lass es festlich und lustig aussehen.',
              emoji: '🎪',
              color: AppColors.secondary,
            ),
            EditOption(
              id: 'baby_elephant',
              titleEn: 'Baby Elephant',
              titleDe: 'Baby-Elefant',
              descriptionEn: 'Make it smaller and super cute!',
              descriptionDe: 'Mach ihn kleiner und super süß!',
              promptEn:
                  'Transform this child\'s elephant drawing into an adorable baby elephant. Make it look smaller and cuter with big innocent eyes, chubby body, shorter legs, and a playful expression. Add soft, gentle colors and maybe a small toy or blanket. Make it look extra cuddly and sweet.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Elefanten in einen bezaubernden Baby-Elefanten. Lass ihn kleiner und süßer aussehen mit großen unschuldigen Augen, molligem Körper, kürzeren Beinen und einem verspielten Ausdruck. Füge weiche, sanfte Farben und vielleicht ein kleines Spielzeug oder eine Decke hinzu. Lass ihn extra kuschelig und süß aussehen.',
              emoji: '🍼',
              color: AppColors.accent,
            ),
            EditOption(
              id: 'safari_scene',
              titleEn: 'Safari Adventure',
              titleDe: 'Safari-Abenteuer',
              descriptionEn: 'Add African savanna background!',
              descriptionDe: 'Füge afrikanischen Savannenhintergrund hinzu!',
              promptEn:
                  'Enhance this child\'s elephant drawing by adding an African savanna background. Include acacia trees, golden grass, a sunset sky with warm orange and yellow colors, and maybe other safari animals in the distance. Make the elephant look majestic in its natural habitat.',
              promptDe:
                  'Verbessere diese Kinderzeichnung eines Elefanten, indem du einen afrikanischen Savannenhintergrund hinzufügst. Füge Akazienbäume, goldenes Gras, einen Sonnenuntergangshimmel mit warmen Orange- und Gelbtönen und vielleicht andere Safari-Tiere in der Ferne hinzu. Lass den Elefanten majestätisch in seinem natürlichen Lebensraum aussehen.',
              emoji: '🌍',
              color: AppColors.success,
            ),
          ],
        ),
      ],
    ),

    // Objects Category
    DrawingCategory(
      id: 'objects',
      titleEn: 'Objects',
      titleDe: 'Objekte',
      descriptionEn: 'Learn to draw everyday objects and shapes!',
      descriptionDe: 'Lerne alltägliche Gegenstände und Formen zu zeichnen!',
      icon: '⚽',
      color: AppColors.accent,
      drawings: [
        Drawing(
          id: 'house',
          nameEn: 'House',
          nameDe: 'Haus',
          emoji: '🏠',
          steps: [
            DrawingStep(
              stepEn: 'Draw a square for the house base',
              stepDe: 'Zeichne ein Quadrat für die Hausbasis',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add a triangle on top for the roof',
              stepDe: 'Füge ein Dreieck oben für das Dach hinzu',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Draw a door and windows to complete the house',
              stepDe:
                  'Zeichne eine Tür und Fenster, um das Haus zu vervollständigen',
              stepImg: '', // Will be populated from API
            ),
          ],
          editOptions: [
            EditOption(
              id: 'dream_house',
              titleEn: 'Dream House',
              titleDe: 'Traumhaus',
              descriptionEn: 'Add a garden, chimney smoke, and decorations!',
              descriptionDe:
                  'Füge einen Garten, Kaminrauch und Dekoration hinzu!',
              promptEn:
                  'Transform this child\'s house drawing into a dream house. Add a beautiful garden with flowers and trees, smoke coming from the chimney, curtains in the windows, a path to the door, a fence, and decorative details. Use warm, inviting colors and make it look cozy and welcoming.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Hauses in ein Traumhaus. Füge einen schönen Garten mit Blumen und Bäumen, Rauch aus dem Kamin, Vorhänge in den Fenstern, einen Weg zur Tür, einen Zaun und dekorative Details hinzu. Verwende warme, einladende Farben und lass es gemütlich und einladend aussehen.',
              emoji: '🏡',
              color: AppColors.success,
            ),
            EditOption(
              id: 'castle_house',
              titleEn: 'Make it a Castle',
              titleDe: 'Zu einem Schloss machen',
              descriptionEn: 'Transform into a magical castle!',
              descriptionDe: 'Verwandle in ein magisches Schloss!',
              promptEn:
                  'Transform this child\'s house drawing into a magical fairy tale castle. Add towers with pointed roofs, flags on top, stone walls, a drawbridge, and maybe a moat. Use fantasy colors like purple, blue, and gold. Add sparkles and magical elements to make it look enchanted.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Hauses in ein magisches Märchenschloss. Füge Türme mit spitzen Dächern, Flaggen oben, Steinmauern, eine Zugbrücke und vielleicht einen Wassergraben hinzu. Verwende Fantasy-Farben wie Lila, Blau und Gold. Füge Glitzer und magische Elemente hinzu, um es verzaubert aussehen zu lassen.',
              emoji: '🏰',
              color: AppColors.primary,
            ),
            EditOption(
              id: 'cozy_cottage',
              titleEn: 'Cozy Cottage',
              titleDe: 'Gemütliches Häuschen',
              descriptionEn: 'Make it a warm, cozy cottage!',
              descriptionDe: 'Mach es zu einem warmen, gemütlichen Häuschen!',
              promptEn:
                  'Transform this child\'s house drawing into a warm, cozy cottage. Add a thatched or wooden roof, glowing windows with warm light inside, a small garden with flowers, a wooden door, and maybe a cat or dog nearby. Use warm earth tones and make it look inviting and homey.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Hauses in ein warmes, gemütliches Häuschen. Füge ein Stroh- oder Holzdach, leuchtende Fenster mit warmem Licht drinnen, einen kleinen Garten mit Blumen, eine Holztür und vielleicht eine Katze oder einen Hund in der Nähe hinzu. Verwende warme Erdtöne und lass es einladend und heimelig aussehen.',
              emoji: '🕯️',
              color: AppColors.accent,
            ),
          ],
        ),
        Drawing(
          id: 'ball',
          nameEn: 'Ball',
          nameDe: 'Ball',
          emoji: '⚽',
          steps: [
            DrawingStep(
              stepEn: 'Draw a perfect circle for the ball',
              stepDe: 'Zeichne einen perfekten Kreis für den Ball',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add curved lines to make it look like a soccer ball',
              stepDe:
                  'Füge gebogene Linien hinzu, damit es wie ein Fußball aussieht',
              stepImg: '', // Will be populated from API
            ),
          ],
          editOptions: [
            EditOption(
              id: 'sports_ball',
              titleEn: 'Sports Style',
              titleDe: 'Sport-Stil',
              descriptionEn: 'Make it look like a real sports ball!',
              descriptionDe: 'Lass es wie einen echten Sportball aussehen!',
              promptEn:
                  'Transform this child\'s ball drawing into a realistic sports ball. Add detailed patterns, textures, and shading to make it look like a professional soccer ball with black and white pentagons. Make it three-dimensional with highlights and shadows.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Balls in einen realistischen Sportball. Füge detaillierte Muster, Texturen und Schattierungen hinzu, um ihn wie einen professionellen Fußball mit schwarzen und weißen Fünfecken aussehen zu lassen. Mache ihn dreidimensional mit Highlights und Schatten.',
              emoji: '⚽',
              color: AppColors.primary,
            ),
            EditOption(
              id: 'rainbow_ball',
              titleEn: 'Rainbow Ball',
              titleDe: 'Regenbogen-Ball',
              descriptionEn: 'Add colorful rainbow patterns!',
              descriptionDe: 'Füge bunte Regenbogenmuster hinzu!',
              promptEn:
                  'Transform this child\'s ball drawing into a vibrant rainbow ball. Add colorful stripes or swirls using all rainbow colors: red, orange, yellow, green, blue, and purple. Make it bright, cheerful, and eye-catching with a glossy, shiny surface.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Balls in einen lebendigen Regenbogen-Ball. Füge bunte Streifen oder Wirbel mit allen Regenbogenfarben hinzu: Rot, Orange, Gelb, Grün, Blau und Lila. Mache ihn hell, fröhlich und auffällig mit einer glänzenden Oberfläche.',
              emoji: '🌈',
              color: AppColors.accent,
            ),
            EditOption(
              id: 'glowing_ball',
              titleEn: 'Glowing Ball',
              titleDe: 'Leuchtender Ball',
              descriptionEn: 'Make it glow with magical light!',
              descriptionDe: 'Lass ihn mit magischem Licht leuchten!',
              promptEn:
                  'Transform this child\'s ball drawing into a magical glowing ball. Add bright neon colors, light rays, sparkles, and a glowing aura around it. Make it look like it\'s emitting light with electric blue or bright green colors.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Balls in einen magischen leuchtenden Ball. Füge helle Neonfarben, Lichtstrahlen, Glitzer und eine leuchtende Aura darum herum hinzu. Lass ihn aussehen, als würde er Licht ausstrahlen mit elektrischem Blau oder hellem Grün.',
              emoji: '✨',
              color: AppColors.success,
            ),
          ],
        ),
        Drawing(
          id: 'star',
          nameEn: 'Star',
          nameDe: 'Stern',
          emoji: '⭐',
          steps: [
            DrawingStep(
              stepEn: 'Draw five points around in a circle',
              stepDe: 'Zeichne fünf Punkte in einem Kreis',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Connect the points to make a star shape',
              stepDe: 'Verbinde die Punkte zu einer Sternform',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add small sparkles around the star',
              stepDe: 'Füge kleine Funken um den Stern hinzu',
              stepImg: '', // Will be populated from API
            ),
          ],
          editOptions: [
            EditOption(
              id: 'shooting_star',
              titleEn: 'Shooting Star',
              titleDe: 'Sternschnuppe',
              descriptionEn: 'Add a magical tail and sparkles!',
              descriptionDe: 'Füge einen magischen Schweif und Glitzer hinzu!',
              promptEn:
                  'Transform this child\'s star drawing into a beautiful shooting star. Add a long, flowing tail with sparkles and light trails. Use bright yellow and white colors with magical sparkles around it. Make it look like it\'s flying through the night sky.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Sterns in eine wunderschöne Sternschnuppe. Füge einen langen, fließenden Schweif mit Glitzer und Lichtspuren hinzu. Verwende helle Gelb- und Weißtöne mit magischem Glitzer darum herum. Lass ihn aussehen, als würde er durch den Nachthimmel fliegen.',
              emoji: '🌠',
              color: AppColors.accent,
            ),
            EditOption(
              id: 'golden_star',
              titleEn: 'Golden Star',
              titleDe: 'Goldener Stern',
              descriptionEn: 'Make it shine like gold!',
              descriptionDe: 'Lass ihn wie Gold glänzen!',
              promptEn:
                  'Transform this child\'s star drawing into a shiny golden star. Add metallic gold color with highlights and reflections. Make it look three-dimensional with shading and give it a luxurious, precious appearance like a gold medal or trophy.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Sterns in einen glänzenden goldenen Stern. Füge metallische Goldfarbe mit Highlights und Reflexionen hinzu. Mache ihn dreidimensional mit Schattierungen und gib ihm ein luxuriöses, kostbares Aussehen wie eine Goldmedaille oder Trophäe.',
              emoji: '⭐',
              color: AppColors.primary,
            ),
            EditOption(
              id: 'rainbow_star',
              titleEn: 'Rainbow Star',
              titleDe: 'Regenbogen-Stern',
              descriptionEn: 'Add rainbow colors and magic!',
              descriptionDe: 'Füge Regenbogenfarben und Magie hinzu!',
              promptEn:
                  'Transform this child\'s star drawing into a magical rainbow star. Fill it with gradient rainbow colors flowing through each point. Add sparkles, glitter, and a magical glow. Make it look fantastical and dreamy.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Sterns in einen magischen Regenbogen-Stern. Fülle ihn mit Regenbogenfarbverläufen, die durch jede Spitze fließen. Füge Glitzer, Funkeln und ein magisches Leuchten hinzu. Lass ihn fantastisch und verträumt aussehen.',
              emoji: '🌈',
              color: AppColors.success,
            ),
            EditOption(
              id: 'twinkling_star',
              titleEn: 'Twinkling Star',
              titleDe: 'Funkelnder Stern',
              descriptionEn: 'Make it twinkle and shine!',
              descriptionDe: 'Lass ihn funkeln und leuchten!',
              promptEn:
                  'Transform this child\'s star drawing into a beautifully twinkling star. Add light sparkles, glowing effects, and make it look like it\'s shimmering in the night sky. Use bright white and yellow with star-burst effects around it.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Sterns in einen wunderschön funkelnden Stern. Füge Lichtfunken, Leuchteffekte hinzu und lass ihn aussehen, als würde er am Nachthimmel schimmern. Verwende helles Weiß und Gelb mit Sternexplosionseffekten drumherum.',
              emoji: '✨',
              color: AppColors.secondary,
            ),
          ],
        ),
      ],
    ),

    // Nature Category
    DrawingCategory(
      id: 'nature',
      titleEn: 'Nature',
      titleDe: 'Natur',
      descriptionEn: 'Create beautiful nature scenes and plants!',
      descriptionDe: 'Erschaffe wunderschöne Naturszenen und Pflanzen!',
      icon: '🌳',
      color: AppColors.success,
      drawings: [
        Drawing(
          id: 'tree',
          nameEn: 'Tree',
          nameDe: 'Baum',
          emoji: '🌳',
          steps: [
            DrawingStep(
              stepEn: 'Draw a tall rectangle for the tree trunk',
              stepDe: 'Zeichne ein hohes Rechteck für den Baumstamm',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add branches coming out from the trunk',
              stepDe: 'Füge Äste hinzu, die aus dem Stamm kommen',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Draw a big cloud shape for the leaves',
              stepDe: 'Zeichne eine große Wolkenform für die Blätter',
              stepImg: '', // Will be populated from API
            ),
          ],
          editOptions: [
            EditOption(
              id: 'autumn_tree',
              titleEn: 'Autumn Colors',
              titleDe: 'Herbstfarben',
              descriptionEn: 'Add beautiful fall colors!',
              descriptionDe: 'Füge schöne Herbstfarben hinzu!',
              promptEn:
                  'Transform this child\'s tree drawing into a beautiful autumn tree. Add warm fall colors like orange, red, yellow, and brown to the leaves. Make some leaves falling down. Use rich, warm tones and create a cozy autumn atmosphere.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Baumes in einen wunderschönen Herbstbaum. Füge warme Herbstfarben wie Orange, Rot, Gelb und Braun zu den Blättern hinzu. Lass einige Blätter herunterfallen. Verwende satte, warme Töne und schaffe eine gemütliche Herbstatmosphäre.',
              emoji: '🍂',
              color: AppColors.accent,
            ),
            EditOption(
              id: 'cherry_blossom',
              titleEn: 'Cherry Blossom',
              titleDe: 'Kirschblüte',
              descriptionEn: 'Transform into a pink flowering tree!',
              descriptionDe: 'Verwandle in einen rosa blühenden Baum!',
              promptEn:
                  'Transform this child\'s tree drawing into a beautiful cherry blossom tree. Add delicate pink and white flowers covering the branches. Include some petals floating in the air. Make it look magical and springtime with soft, pastel colors.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Baumes in einen wunderschönen Kirschblütenbaum. Füge zarte rosa und weiße Blüten hinzu, die die Äste bedecken. Füge einige Blütenblätter hinzu, die in der Luft schweben. Lass ihn magisch und frühlingshaft aussehen mit weichen Pastellfarben.',
              emoji: '🌸',
              color: AppColors.primary,
            ),
            EditOption(
              id: 'magical_tree',
              titleEn: 'Magical Tree',
              titleDe: 'Magischer Baum',
              descriptionEn: 'Add sparkles and fantasy elements!',
              descriptionDe: 'Füge Glitzer und Fantasy-Elemente hinzu!',
              promptEn:
                  'Transform this child\'s tree drawing into a magical fantasy tree. Add glowing leaves with sparkles, maybe a fairy door at the base, mushrooms around it, and magical lights. Use vibrant colors with purple, blue, and green tones. Make it look enchanted.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Baumes in einen magischen Fantasy-Baum. Füge leuchtende Blätter mit Glitzer hinzu, vielleicht eine Feentür an der Basis, Pilze drumherum und magische Lichter. Verwende lebendige Farben mit Lila-, Blau- und Grüntönen. Lass ihn verzaubert aussehen.',
              emoji: '✨',
              color: AppColors.success,
            ),
            EditOption(
              id: 'christmas_tree',
              titleEn: 'Christmas Tree',
              titleDe: 'Weihnachtsbaum',
              descriptionEn: 'Decorate it for Christmas!',
              descriptionDe: 'Dekoriere ihn für Weihnachten!',
              promptEn:
                  'Transform this child\'s tree drawing into a festive Christmas tree. Add colorful ornaments, lights, tinsel, a star on top, and presents underneath. Use red, green, gold, and silver colors. Make it look cheerful and festive.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Baumes in einen festlichen Weihnachtsbaum. Füge bunte Kugeln, Lichter, Lametta, einen Stern oben und Geschenke darunter hinzu. Verwende Rot, Grün, Gold und Silber. Lass ihn fröhlich und festlich aussehen.',
              emoji: '🎄',
              color: AppColors.secondary,
            ),
          ],
        ),
        Drawing(
          id: 'flower',
          nameEn: 'Flower',
          nameDe: 'Blume',
          emoji: '🌸',
          steps: [
            DrawingStep(
              stepEn: 'Draw a small circle in the middle for the center',
              stepDe:
                  'Zeichne einen kleinen Kreis in die Mitte für das Zentrum',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Draw oval petals around the center',
              stepDe: 'Zeichne ovale Blütenblätter um das Zentrum',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add a stem and small leaves',
              stepDe: 'Füge einen Stiel und kleine Blätter hinzu',
              stepImg: '', // Will be populated from API
            ),
          ],
          editOptions: [
            EditOption(
              id: 'rainbow_flower',
              titleEn: 'Rainbow Flower',
              titleDe: 'Regenbogen-Blume',
              descriptionEn: 'Add rainbow colored petals!',
              descriptionDe: 'Füge regenbogenfarbene Blütenblätter hinzu!',
              promptEn:
                  'Transform this child\'s flower drawing into a magical rainbow flower. Make each petal a different rainbow color: red, orange, yellow, green, blue, and purple. Add sparkles and make it look vibrant and cheerful.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Blume in eine magische Regenbogen-Blume. Mache jedes Blütenblatt in einer anderen Regenbogenfarbe: Rot, Orange, Gelb, Grün, Blau und Lila. Füge Glitzer hinzu und lass sie lebendig und fröhlich aussehen.',
              emoji: '🌈',
              color: AppColors.primary,
            ),
            EditOption(
              id: 'rose_flower',
              titleEn: 'Beautiful Rose',
              titleDe: 'Wunderschöne Rose',
              descriptionEn: 'Transform into an elegant rose!',
              descriptionDe: 'Verwandle in eine elegante Rose!',
              promptEn:
                  'Transform this child\'s flower drawing into a beautiful red rose. Add detailed layered petals, thorns on the stem, and rich red color. Make it look elegant and romantic with soft shading and highlights.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Blume in eine wunderschöne rote Rose. Füge detaillierte geschichtete Blütenblätter, Dornen am Stiel und satte rote Farbe hinzu. Lass sie elegant und romantisch aussehen mit weichen Schattierungen und Highlights.',
              emoji: '🌹',
              color: AppColors.accent,
            ),
            EditOption(
              id: 'sunflower',
              titleEn: 'Bright Sunflower',
              titleDe: 'Helle Sonnenblume',
              descriptionEn: 'Make it a big, happy sunflower!',
              descriptionDe:
                  'Mach sie zu einer großen, fröhlichen Sonnenblume!',
              promptEn:
                  'Transform this child\'s flower drawing into a bright, cheerful sunflower. Add large yellow petals, a brown center with seeds, and make it big and bold. Use warm, sunny colors and make it look happy and inviting.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Blume in eine helle, fröhliche Sonnenblume. Füge große gelbe Blütenblätter, eine braune Mitte mit Samen hinzu und mache sie groß und kräftig. Verwende warme, sonnige Farben und lass sie glücklich und einladend aussehen.',
              emoji: '🌻',
              color: AppColors.success,
            ),
            EditOption(
              id: 'tulip_flower',
              titleEn: 'Pretty Tulip',
              titleDe: 'Hübsche Tulpe',
              descriptionEn: 'Transform into a colorful tulip!',
              descriptionDe: 'Verwandle in eine bunte Tulpe!',
              promptEn:
                  'Transform this child\'s flower drawing into a beautiful tulip. Add a cup-shaped flower with smooth petals in bright colors like pink, red, or yellow. Make the stem straight and elegant with simple leaves.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Blume in eine wunderschöne Tulpe. Füge eine becherförmige Blüte mit glatten Blütenblättern in hellen Farben wie Rosa, Rot oder Gelb hinzu. Mache den Stiel gerade und elegant mit einfachen Blättern.',
              emoji: '🌷',
              color: AppColors.secondary,
            ),
          ],
        ),
        Drawing(
          id: 'sun',
          nameEn: 'Sun',
          nameDe: 'Sonne',
          emoji: '☀️',
          steps: [
            DrawingStep(
              stepEn: 'Draw a big circle for the sun',
              stepDe: 'Zeichne einen großen Kreis für die Sonne',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add lines coming out like sun rays',
              stepDe: 'Füge Linien hinzu, die wie Sonnenstrahlen aussehen',
              stepImg: '', // Will be populated from API
            ),
          ],
          editOptions: [
            EditOption(
              id: 'happy_sun',
              titleEn: 'Happy Sun Face',
              titleDe: 'Fröhliches Sonnengesicht',
              descriptionEn: 'Add a smiling face and personality!',
              descriptionDe:
                  'Füge ein lächelndes Gesicht und Persönlichkeit hinzu!',
              promptEn:
                  'Transform this child\'s sun drawing into a happy, smiling sun with a friendly face. Add big eyes, a warm smile, rosy cheeks, and make the rays look lively. Use bright yellow and orange colors to make it cheerful and welcoming.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Sonne in eine fröhliche, lächelnde Sonne mit einem freundlichen Gesicht. Füge große Augen, ein warmes Lächeln, rosige Wangen hinzu und lass die Strahlen lebendig aussehen. Verwende helle Gelb- und Orangetöne, um sie fröhlich und einladend zu machen.',
              emoji: '😊',
              color: AppColors.accent,
            ),
            EditOption(
              id: 'sunset_sun',
              titleEn: 'Sunset Colors',
              titleDe: 'Sonnenuntergangsfarben',
              descriptionEn: 'Add beautiful sunset colors!',
              descriptionDe: 'Füge wunderschöne Sonnenuntergangsfarben hinzu!',
              promptEn:
                  'Transform this child\'s sun drawing into a beautiful sunset sun. Use warm gradient colors: orange, pink, red, and purple. Add clouds around it and make it look like it\'s setting on the horizon with a dreamy, peaceful atmosphere.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Sonne in eine wunderschöne Sonnenuntergangssonne. Verwende warme Verlaufsfarben: Orange, Rosa, Rot und Lila. Füge Wolken drumherum hinzu und lass sie aussehen, als würde sie am Horizont untergehen mit einer verträumten, friedlichen Atmosphäre.',
              emoji: '🌅',
              color: AppColors.primary,
            ),
            EditOption(
              id: 'glowing_sun',
              titleEn: 'Glowing Sun',
              titleDe: 'Leuchtende Sonne',
              descriptionEn: 'Make it glow with intense light!',
              descriptionDe: 'Lass sie mit intensivem Licht leuchten!',
              promptEn:
                  'Transform this child\'s sun drawing into a brilliantly glowing sun. Add intense light rays, a bright glowing aura, lens flares, and sparkles. Use bright yellow and white with a powerful, radiant appearance.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Sonne in eine brillant leuchtende Sonne. Füge intensive Lichtstrahlen, eine hell leuchtende Aura, Lens Flares und Glitzer hinzu. Verwende helles Gelb und Weiß mit einem kraftvollen, strahlenden Aussehen.',
              emoji: '✨',
              color: AppColors.success,
            ),
            EditOption(
              id: 'cool_sunglasses',
              titleEn: 'Cool Sun with Sunglasses',
              titleDe: 'Coole Sonne mit Sonnenbrille',
              descriptionEn: 'Make it look cool with sunglasses!',
              descriptionDe: 'Lass sie cool mit Sonnenbrille aussehen!',
              promptEn:
                  'Transform this child\'s sun drawing into a cool, fun sun wearing sunglasses. Add stylish sunglasses, a confident smile, and maybe a thumbs up. Make it look trendy and fun with bright colors.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Sonne in eine coole, lustige Sonne mit Sonnenbrille. Füge stylische Sonnenbrille, ein selbstbewusstes Lächeln und vielleicht einen Daumen hoch hinzu. Lass sie trendy und lustig aussehen mit hellen Farben.',
              emoji: '😎',
              color: AppColors.secondary,
            ),
          ],
        ),
      ],
    ),

    // Vehicles Category
    DrawingCategory(
      id: 'vehicles',
      titleEn: 'Vehicles',
      titleDe: 'Fahrzeuge',
      descriptionEn: 'Draw cars, planes, and other vehicles!',
      descriptionDe: 'Zeichne Autos, Flugzeuge und andere Fahrzeuge!',
      icon: '🚗',
      color: AppColors.secondary,
      drawings: [
        Drawing(
          id: 'car',
          nameEn: 'Car',
          nameDe: 'Auto',
          emoji: '🚗',
          steps: [
            DrawingStep(
              stepEn: 'Draw a rectangle for the car body',
              stepDe: 'Zeichne ein Rechteck für die Autokarosserie',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add two circles below for wheels',
              stepDe: 'Füge zwei Kreise unten für die Räder hinzu',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add windows, doors, and headlights',
              stepDe: 'Füge Fenster, Türen und Scheinwerfer hinzu',
              stepImg: '', // Will be populated from API
            ),
          ],
          editOptions: [
            EditOption(
              id: 'race_car',
              titleEn: 'Race Car',
              titleDe: 'Rennwagen',
              descriptionEn: 'Transform into a fast race car!',
              descriptionDe: 'Verwandle in einen schnellen Rennwagen!',
              promptEn:
                  'Transform this child\'s car drawing into a cool race car. Add racing stripes, a number on the side, spoiler, and racing decals. Use bright colors like red or blue with white stripes. Make it look fast and sporty.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Autos in einen coolen Rennwagen. Füge Rennstreifen, eine Nummer an der Seite, einen Spoiler und Rennaufkleber hinzu. Verwende helle Farben wie Rot oder Blau mit weißen Streifen. Lass ihn schnell und sportlich aussehen.',
              emoji: '🏎️',
              color: AppColors.accent,
            ),
            EditOption(
              id: 'police_car',
              titleEn: 'Police Car',
              titleDe: 'Polizeiauto',
              descriptionEn: 'Make it a police car with lights!',
              descriptionDe: 'Mach es zu einem Polizeiauto mit Lichtern!',
              promptEn:
                  'Transform this child\'s car drawing into a police car. Add blue and white colors, police lights on top, police badge or text on the side, and make it look official. Include flashing light effects.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Autos in ein Polizeiauto. Füge blaue und weiße Farben, Polizeilichter oben, ein Polizeiabzeichen oder Text an der Seite hinzu und lass es offiziell aussehen. Füge blinkende Lichteffekte hinzu.',
              emoji: '🚓',
              color: AppColors.primary,
            ),
            EditOption(
              id: 'rainbow_car',
              titleEn: 'Rainbow Car',
              titleDe: 'Regenbogen-Auto',
              descriptionEn: 'Add colorful rainbow paint!',
              descriptionDe: 'Füge bunte Regenbogenfarbe hinzu!',
              promptEn:
                  'Transform this child\'s car drawing into a vibrant rainbow car. Paint it with rainbow stripes or gradient colors using red, orange, yellow, green, blue, and purple. Add sparkles and make it look fun and magical.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Autos in ein lebendiges Regenbogen-Auto. Bemale es mit Regenbogenstreifen oder Verlaufsfarben mit Rot, Orange, Gelb, Grün, Blau und Lila. Füge Glitzer hinzu und lass es lustig und magisch aussehen.',
              emoji: '🌈',
              color: AppColors.success,
            ),
            EditOption(
              id: 'fire_truck',
              titleEn: 'Fire Truck',
              titleDe: 'Feuerwehrauto',
              descriptionEn: 'Transform into a fire truck!',
              descriptionDe: 'Verwandle in ein Feuerwehrauto!',
              promptEn:
                  'Transform this child\'s car drawing into a fire truck. Add red color, a ladder on top, fire hose, emergency lights, and firefighter equipment. Make it look heroic and ready for action.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Autos in ein Feuerwehrauto. Füge rote Farbe, eine Leiter oben, einen Feuerwehrschlauch, Notlichter und Feuerwehrausrüstung hinzu. Lass es heldenhaft und einsatzbereit aussehen.',
              emoji: '🚒',
              color: AppColors.secondary,
            ),
          ],
        ),
        Drawing(
          id: 'airplane',
          nameEn: 'Airplane',
          nameDe: 'Flugzeug',
          emoji: '✈️',
          steps: [
            DrawingStep(
              stepEn: 'Draw an oval for the airplane body',
              stepDe: 'Zeichne ein Oval für den Flugzeugkörper',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add wings on both sides of the body',
              stepDe: 'Füge Flügel an beiden Seiten des Körpers hinzu',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add the tail and propeller to complete the plane',
              stepDe:
                  'Füge das Heck und den Propeller hinzu, um das Flugzeug zu vervollständigen',
              stepImg: '', // Will be populated from API
            ),
          ],
          editOptions: [
            EditOption(
              id: 'jet_plane',
              titleEn: 'Fighter Jet',
              titleDe: 'Kampfjet',
              descriptionEn: 'Transform into a cool fighter jet!',
              descriptionDe: 'Verwandle in einen coolen Kampfjet!',
              promptEn:
                  'Transform this child\'s airplane drawing into a sleek fighter jet. Make it more angular and aerodynamic with swept-back wings, military colors like gray or camouflage, and add jet engines. Make it look fast and powerful.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Flugzeugs in einen schlanken Kampfjet. Mache ihn eckiger und aerodynamischer mit zurückgeschwungenen Flügeln, Militärfarben wie Grau oder Tarnung und füge Düsentriebwerke hinzu. Lass ihn schnell und kraftvoll aussehen.',
              emoji: '✈️',
              color: AppColors.secondary,
            ),
            EditOption(
              id: 'rainbow_plane',
              titleEn: 'Rainbow Plane',
              titleDe: 'Regenbogen-Flugzeug',
              descriptionEn: 'Add rainbow colors and trails!',
              descriptionDe: 'Füge Regenbogenfarben und Spuren hinzu!',
              promptEn:
                  'Transform this child\'s airplane drawing into a colorful rainbow plane. Paint it with bright rainbow colors and add colorful smoke trails behind it. Make it look cheerful and festive with vibrant colors.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Flugzeugs in ein buntes Regenbogen-Flugzeug. Bemale es mit hellen Regenbogenfarben und füge bunte Rauchspuren dahinter hinzu. Lass es fröhlich und festlich aussehen mit lebendigen Farben.',
              emoji: '🌈',
              color: AppColors.accent,
            ),
            EditOption(
              id: 'clouds_sky',
              titleEn: 'Flying in Clouds',
              titleDe: 'Fliegen in Wolken',
              descriptionEn: 'Add clouds and sky background!',
              descriptionDe: 'Füge Wolken und Himmelhintergrund hinzu!',
              promptEn:
                  'Enhance this child\'s airplane drawing by adding a beautiful sky background. Include fluffy white clouds, blue sky, maybe birds flying nearby, and sun rays. Make it look like it\'s peacefully flying through a beautiful day.',
              promptDe:
                  'Verbessere diese Kinderzeichnung eines Flugzeugs, indem du einen wunderschönen Himmelhintergrund hinzufügst. Füge flauschige weiße Wolken, blauen Himmel, vielleicht Vögel in der Nähe und Sonnenstrahlen hinzu. Lass es aussehen, als würde es friedlich durch einen schönen Tag fliegen.',
              emoji: '☁️',
              color: AppColors.primary,
            ),
            EditOption(
              id: 'space_rocket',
              titleEn: 'Space Rocket',
              titleDe: 'Weltraumrakete',
              descriptionEn: 'Transform into a space rocket!',
              descriptionDe: 'Verwandle in eine Weltraumrakete!',
              promptEn:
                  'Transform this child\'s airplane drawing into a space rocket. Add a pointed nose cone, rocket boosters with flames, space colors like silver and blue, and stars in the background. Make it look like it\'s heading to space.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Flugzeugs in eine Weltraumrakete. Füge eine spitze Nasenspitze, Raketentriebwerke mit Flammen, Weltraumfarben wie Silber und Blau und Sterne im Hintergrund hinzu. Lass es aussehen, als würde es ins All fliegen.',
              emoji: '🚀',
              color: AppColors.success,
            ),
          ],
        ),
      ],
    ),

    // Food Category
    DrawingCategory(
      id: 'food',
      titleEn: 'Food',
      titleDe: 'Essen',
      descriptionEn: 'Draw delicious food and treats!',
      descriptionDe: 'Zeichne leckeres Essen und Leckereien!',
      icon: '🍎',
      color: AppColors.error,
      drawings: [
        Drawing(
          id: 'apple',
          nameEn: 'Apple',
          nameDe: 'Apfel',
          emoji: '🍎',
          steps: [
            DrawingStep(
              stepEn: 'Draw a round shape with a small dent on top',
              stepDe: 'Zeichne eine runde Form mit einer kleinen Delle oben',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add a small stem and leaf on top',
              stepDe: 'Füge einen kleinen Stiel und ein Blatt oben hinzu',
              stepImg: '', // Will be populated from API
            ),
          ],
          editOptions: [
            EditOption(
              id: 'golden_apple',
              titleEn: 'Golden Apple',
              titleDe: 'Goldener Apfel',
              descriptionEn: 'Make it shine like gold!',
              descriptionDe: 'Lass ihn wie Gold glänzen!',
              promptEn:
                  'Transform this child\'s apple drawing into a magical golden apple. Add metallic gold color with shiny highlights and reflections. Make it look precious and special, like a fairy tale golden apple with sparkles around it.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Apfels in einen magischen goldenen Apfel. Füge metallische Goldfarbe mit glänzenden Highlights und Reflexionen hinzu. Lass ihn kostbar und besonders aussehen, wie ein Märchen-Goldapfel mit Glitzer drumherum.',
              emoji: '✨',
              color: AppColors.accent,
            ),
            EditOption(
              id: 'candy_apple',
              titleEn: 'Candy Apple',
              titleDe: 'Kandierter Apfel',
              descriptionEn: 'Transform into a sweet candy apple!',
              descriptionDe: 'Verwandle in einen süßen kandierten Apfel!',
              promptEn:
                  'Transform this child\'s apple drawing into a delicious candy apple. Add a shiny red candy coating, a wooden stick, and maybe some sprinkles or decorations. Make it look glossy, sweet, and tempting.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Apfels in einen leckeren kandierten Apfel. Füge eine glänzende rote Zuckerglasur, einen Holzstab und vielleicht einige Streusel oder Dekorationen hinzu. Lass ihn glänzend, süß und verlockend aussehen.',
              emoji: '🍎',
              color: AppColors.primary,
            ),
            EditOption(
              id: 'rainbow_apple',
              titleEn: 'Rainbow Apple',
              titleDe: 'Regenbogen-Apfel',
              descriptionEn: 'Add magical rainbow colors!',
              descriptionDe: 'Füge magische Regenbogenfarben hinzu!',
              promptEn:
                  'Transform this child\'s apple drawing into a magical rainbow apple. Use gradient rainbow colors flowing across the apple surface. Add sparkles and a magical glow to make it look fantastical and enchanted.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Apfels in einen magischen Regenbogen-Apfel. Verwende Regenbogenfarbverläufe, die über die Apfeloberfläche fließen. Füge Glitzer und ein magisches Leuchten hinzu, um ihn fantastisch und verzaubert aussehen zu lassen.',
              emoji: '🌈',
              color: AppColors.success,
            ),
            EditOption(
              id: 'green_apple',
              titleEn: 'Fresh Green Apple',
              titleDe: 'Frischer Grüner Apfel',
              descriptionEn: 'Make it a crisp green apple!',
              descriptionDe: 'Mach ihn zu einem knackigen grünen Apfel!',
              promptEn:
                  'Transform this child\'s apple drawing into a fresh, crisp green apple. Add bright green color with highlights to make it look juicy and fresh. Include water droplets to make it look refreshing and delicious.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Apfels in einen frischen, knackigen grünen Apfel. Füge helle grüne Farbe mit Highlights hinzu, um ihn saftig und frisch aussehen zu lassen. Füge Wassertropfen hinzu, um ihn erfrischend und lecker aussehen zu lassen.',
              emoji: '🍏',
              color: AppColors.secondary,
            ),
          ],
        ),
        Drawing(
          id: 'pizza',
          nameEn: 'Pizza',
          nameDe: 'Pizza',
          emoji: '🍕',
          steps: [
            DrawingStep(
              stepEn: 'Draw a triangle for the pizza slice',
              stepDe: 'Zeichne ein Dreieck für das Pizzastück',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add circles and shapes for toppings',
              stepDe: 'Füge Kreise und Formen für Beläge hinzu',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Make the crust look thick and tasty',
              stepDe: 'Lass die Kruste dick und lecker aussehen',
              stepImg: '', // Will be populated from API
            ),
          ],
          editOptions: [
            EditOption(
              id: 'deluxe_pizza',
              titleEn: 'Deluxe Pizza',
              titleDe: 'Deluxe-Pizza',
              descriptionEn: 'Add lots of delicious toppings!',
              descriptionDe: 'Füge viele leckere Beläge hinzu!',
              promptEn:
                  'Transform this child\'s pizza drawing into a delicious deluxe pizza. Add lots of colorful toppings: pepperoni, mushrooms, peppers, olives, cheese stretching, and make it look mouth-watering. Use rich, appetizing colors.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Pizza in eine leckere Deluxe-Pizza. Füge viele bunte Beläge hinzu: Pepperoni, Pilze, Paprika, Oliven, dehnenden Käse und lass sie appetitlich aussehen. Verwende satte, appetitanregende Farben.',
              emoji: '🍕',
              color: AppColors.accent,
            ),
            EditOption(
              id: 'rainbow_pizza',
              titleEn: 'Rainbow Pizza',
              titleDe: 'Regenbogen-Pizza',
              descriptionEn: 'Make it colorful and fun!',
              descriptionDe: 'Mach sie bunt und lustig!',
              promptEn:
                  'Transform this child\'s pizza drawing into a fun rainbow pizza. Add colorful toppings in rainbow colors: red tomatoes, orange cheese, yellow peppers, green olives, blue... make it creative and colorful. Make it look playful and magical.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Pizza in eine lustige Regenbogen-Pizza. Füge bunte Beläge in Regenbogenfarben hinzu: rote Tomaten, oranger Käse, gelbe Paprika, grüne Oliven... mach es kreativ und bunt. Lass sie verspielt und magisch aussehen.',
              emoji: '🌈',
              color: AppColors.primary,
            ),
            EditOption(
              id: 'hot_spicy_pizza',
              titleEn: 'Hot & Spicy Pizza',
              titleDe: 'Scharfe Pizza',
              descriptionEn: 'Add spicy peppers and flames!',
              descriptionDe: 'Füge scharfe Paprika und Flammen hinzu!',
              promptEn:
                  'Transform this child\'s pizza drawing into a hot and spicy pizza. Add red hot peppers, flames around it, and make it look fiery. Use red, orange, and yellow colors to show it\'s super spicy and hot.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Pizza in eine heiße und scharfe Pizza. Füge rote scharfe Paprika, Flammen drumherum hinzu und lass sie feurig aussehen. Verwende Rot, Orange und Gelb, um zu zeigen, dass sie super scharf und heiß ist.',
              emoji: '🌶️',
              color: AppColors.success,
            ),
            EditOption(
              id: 'cheese_lover_pizza',
              titleEn: 'Cheese Lover Pizza',
              titleDe: 'Käse-Liebhaber-Pizza',
              descriptionEn: 'Add extra melted cheese!',
              descriptionDe: 'Füge extra geschmolzenen Käse hinzu!',
              promptEn:
                  'Transform this child\'s pizza drawing into a cheese lover\'s dream pizza. Add lots of melted, stretchy cheese dripping down. Make it look extra cheesy and delicious with golden yellow cheese everywhere.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Pizza in eine Traumpizza für Käseliebhaber. Füge viel geschmolzenen, dehnbaren Käse hinzu, der heruntertropft. Lass sie extra käsig und lecker aussehen mit goldenem gelbem Käse überall.',
              emoji: '🧀',
              color: AppColors.secondary,
            ),
          ],
        ),
      ],
    ),

    // Characters Category
    DrawingCategory(
      id: 'characters',
      titleEn: 'Characters',
      titleDe: 'Charaktere',
      descriptionEn: 'Create magical characters and people!',
      descriptionDe: 'Erschaffe magische Charaktere und Menschen!',
      icon: '👑',
      color: AppColors.primaryDark,
      drawings: [
        Drawing(
          id: 'princess',
          nameEn: 'Princess',
          nameDe: 'Prinzessin',
          emoji: '👸',
          steps: [
            DrawingStep(
              stepEn: 'Draw a circle for the princess head',
              stepDe: 'Zeichne einen Kreis für den Prinzessinnenkopf',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add a beautiful crown on top of her head',
              stepDe: 'Füge eine wunderschöne Krone auf ihren Kopf hinzu',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Draw a long, flowing dress',
              stepDe: 'Zeichne ein langes, fließendes Kleid',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add her face and long beautiful hair',
              stepDe: 'Füge ihr Gesicht und langes schönes Haar hinzu',
              stepImg: '', // Will be populated from API
            ),
          ],
          editOptions: [
            EditOption(
              id: 'fairy_princess',
              titleEn: 'Fairy Princess',
              titleDe: 'Feen-Prinzessin',
              descriptionEn: 'Add fairy wings and magic!',
              descriptionDe: 'Füge Feenflügel und Magie hinzu!',
              promptEn:
                  'Transform this child\'s princess drawing into a magical fairy princess. Add beautiful fairy wings, a magic wand with sparkles, glitter around her, and make her dress look more ethereal. Use pastel colors and add magical elements.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Prinzessin in eine magische Feen-Prinzessin. Füge wunderschöne Feenflügel, einen Zauberstab mit Glitzer, Funkeln um sie herum hinzu und lass ihr Kleid ätherischer aussehen. Verwende Pastellfarben und füge magische Elemente hinzu.',
              emoji: '🧚',
              color: AppColors.primary,
            ),
            EditOption(
              id: 'ice_princess',
              titleEn: 'Ice Princess',
              titleDe: 'Eis-Prinzessin',
              descriptionEn: 'Transform into an ice queen!',
              descriptionDe: 'Verwandle in eine Eiskönigin!',
              promptEn:
                  'Transform this child\'s princess drawing into a beautiful ice princess. Add an icy blue dress with snowflake patterns, ice crystals, a sparkling ice crown, and snowflakes around her. Use blue, white, and silver colors.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Prinzessin in eine wunderschöne Eis-Prinzessin. Füge ein eisiges blaues Kleid mit Schneeflockenmustern, Eiskristalle, eine funkelnde Eiskrone und Schneeflocken um sie herum hinzu. Verwende Blau, Weiß und Silber.',
              emoji: '❄️',
              color: AppColors.accent,
            ),
            EditOption(
              id: 'warrior_princess',
              titleEn: 'Warrior Princess',
              titleDe: 'Krieger-Prinzessin',
              descriptionEn: 'Make her brave and strong!',
              descriptionDe: 'Mach sie mutig und stark!',
              promptEn:
                  'Transform this child\'s princess drawing into a brave warrior princess. Add armor pieces, a sword or shield, a cape, and make her look strong and heroic. Keep the crown but make her look ready for adventure.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Prinzessin in eine mutige Krieger-Prinzessin. Füge Rüstungsteile, ein Schwert oder Schild, einen Umhang hinzu und lass sie stark und heldenhaft aussehen. Behalte die Krone, aber lass sie abenteuerbereit aussehen.',
              emoji: '⚔️',
              color: AppColors.success,
            ),
            EditOption(
              id: 'rainbow_princess',
              titleEn: 'Rainbow Princess',
              titleDe: 'Regenbogen-Prinzessin',
              descriptionEn: 'Add rainbow colors everywhere!',
              descriptionDe: 'Füge überall Regenbogenfarben hinzu!',
              promptEn:
                  'Transform this child\'s princess drawing into a magical rainbow princess. Make her dress flow with rainbow colors, add a rainbow crown, colorful hair, and sparkles everywhere. Use all rainbow colors to make her look magical and joyful.',
              promptDe:
                  'Verwandle diese Kinderzeichnung einer Prinzessin in eine magische Regenbogen-Prinzessin. Lass ihr Kleid in Regenbogenfarben fließen, füge eine Regenbogenkrone, buntes Haar und Glitzer überall hinzu. Verwende alle Regenbogenfarben, um sie magisch und fröhlich aussehen zu lassen.',
              emoji: '🌈',
              color: AppColors.secondary,
            ),
          ],
        ),
        Drawing(
          id: 'robot',
          nameEn: 'Robot',
          nameDe: 'Roboter',
          emoji: '🤖',
          steps: [
            DrawingStep(
              stepEn: 'Draw a square for the robot head',
              stepDe: 'Zeichne ein Quadrat für den Roboterkopf',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add a rectangle body with arms and legs',
              stepDe:
                  'Füge einen rechteckigen Körper mit Armen und Beinen hinzu',
              stepImg: '', // Will be populated from API
            ),
            DrawingStep(
              stepEn: 'Add buttons, lights, and robot features',
              stepDe: 'Füge Knöpfe, Lichter und Robotermerkmale hinzu',
              stepImg: '', // Will be populated from API
            ),
          ],
          editOptions: [
            EditOption(
              id: 'colorful_robot',
              titleEn: 'Colorful Robot',
              titleDe: 'Bunter Roboter',
              descriptionEn: 'Add bright colors and patterns!',
              descriptionDe: 'Füge helle Farben und Muster hinzu!',
              promptEn:
                  'Transform this child\'s robot drawing into a colorful, fun robot. Add bright colors like red, blue, yellow, and green. Include colorful buttons, lights, and patterns. Make it look friendly and cheerful.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Roboters in einen bunten, lustigen Roboter. Füge helle Farben wie Rot, Blau, Gelb und Grün hinzu. Füge bunte Knöpfe, Lichter und Muster hinzu. Lass ihn freundlich und fröhlich aussehen.',
              emoji: '🎨',
              color: AppColors.primary,
            ),
            EditOption(
              id: 'space_robot',
              titleEn: 'Space Robot',
              titleDe: 'Weltraum-Roboter',
              descriptionEn: 'Make it a space explorer!',
              descriptionDe: 'Mach ihn zu einem Weltraumforscher!',
              promptEn:
                  'Transform this child\'s robot drawing into a space exploration robot. Add space suit elements, antenna, rocket boosters, and stars around it. Use silver, blue, and white colors. Make it look like it\'s ready for space adventures.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Roboters in einen Weltraum-Erkundungsroboter. Füge Raumanzug-Elemente, Antenne, Raketentriebwerke und Sterne drumherum hinzu. Verwende Silber, Blau und Weiß. Lass ihn aussehen, als wäre er bereit für Weltraumabenteuer.',
              emoji: '🚀',
              color: AppColors.accent,
            ),
            EditOption(
              id: 'friendly_robot',
              titleEn: 'Friendly Robot',
              titleDe: 'Freundlicher Roboter',
              descriptionEn: 'Give it a happy, friendly face!',
              descriptionDe: 'Gib ihm ein glückliches, freundliches Gesicht!',
              promptEn:
                  'Transform this child\'s robot drawing into a super friendly robot. Add a big smile, kind eyes, heart symbols, and make it look warm and welcoming. Use soft colors and make it look like a helpful friend.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Roboters in einen super freundlichen Roboter. Füge ein großes Lächeln, freundliche Augen, Herzsymbole hinzu und lass ihn warm und einladend aussehen. Verwende weiche Farben und lass ihn wie einen hilfreichen Freund aussehen.',
              emoji: '😊',
              color: AppColors.success,
            ),
            EditOption(
              id: 'superhero_robot',
              titleEn: 'Superhero Robot',
              titleDe: 'Superhelden-Roboter',
              descriptionEn: 'Make it a superhero!',
              descriptionDe: 'Mach ihn zu einem Superhelden!',
              promptEn:
                  'Transform this child\'s robot drawing into a superhero robot. Add a cape, superhero emblem on the chest, powerful pose, and maybe energy effects. Use bold colors like red, blue, and gold. Make it look heroic and strong.',
              promptDe:
                  'Verwandle diese Kinderzeichnung eines Roboters in einen Superhelden-Roboter. Füge einen Umhang, ein Superhelden-Emblem auf der Brust, eine kraftvolle Pose und vielleicht Energieeffekte hinzu. Verwende kräftige Farben wie Rot, Blau und Gold. Lass ihn heldenhaft und stark aussehen.',
              emoji: '🦸',
              color: AppColors.secondary,
            ),
          ],
        ),
      ],
    ),
  ];

  // Helper methods
  static DrawingCategory? getCategoryById(String id) {
    try {
      return categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  static Drawing? getDrawingById(String categoryId, String drawingId) {
    final category = getCategoryById(categoryId);
    if (category == null) return null;

    try {
      return category.drawings.firstWhere((drawing) => drawing.id == drawingId);
    } catch (e) {
      return null;
    }
  }

  static List<DrawingStep> getStepsForDrawing(
    String categoryId,
    String drawingId,
  ) {
    final drawing = getDrawingById(categoryId, drawingId);
    return drawing?.steps ?? [];
  }
}
