import 'package:flutter/material.dart';
import 'colors.dart';

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

class DrawingItem {
  final String id;
  final String nameEn;
  final String nameDe;
  final String emoji;
  final List<DrawingStep> steps;

  const DrawingItem({
    required this.id,
    required this.nameEn,
    required this.nameDe,
    required this.emoji,
    required this.steps,
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
  final List<DrawingItem> items;

  const DrawingCategory({
    required this.id,
    required this.titleEn,
    required this.titleDe,
    required this.descriptionEn,
    required this.descriptionDe,
    required this.icon,
    required this.color,
    required this.items,
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
      items: [
        DrawingItem(
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
        ),
        DrawingItem(
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
        ),
        DrawingItem(
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
        ),
        DrawingItem(
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
      items: [
        DrawingItem(
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
        ),
        DrawingItem(
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
        ),
        DrawingItem(
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
      items: [
        DrawingItem(
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
        DrawingItem(
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
        DrawingItem(
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
      items: [
        DrawingItem(
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
        DrawingItem(
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
      items: [
        DrawingItem(
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
        DrawingItem(
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
      items: [
        DrawingItem(
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
        DrawingItem(
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

  static DrawingItem? getDrawingItemById(String categoryId, String itemId) {
    final category = getCategoryById(categoryId);
    if (category == null) return null;

    try {
      return category.items.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }

  static List<DrawingStep> getStepsForDrawing(
    String categoryId,
    String itemId,
  ) {
    final item = getDrawingItemById(categoryId, itemId);
    return item?.steps ?? [];
  }
}
