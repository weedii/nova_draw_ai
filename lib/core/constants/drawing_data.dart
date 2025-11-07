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
  final String stepImg; // base64 image string

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
          editOptions: [],
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
