import 'package:flutter/material.dart';

/// UI model for drawing steps (used in the presentation layer)
/// This is separate from ApiDrawingStep to decouple UI from API structure
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

/// UI model for edit options (used in the presentation layer)
/// This is separate from ApiEditOption to decouple UI from API structure
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

/// UI model for drawings/subjects (used in the presentation layer)
class Drawing {
  final String nameEn;
  final String nameDe;
  final String emoji;
  final int totalSteps;
  final String? thumbnailUrl;

  const Drawing({
    required this.nameEn,
    required this.nameDe,
    required this.emoji,
    required this.totalSteps,
    this.thumbnailUrl,
  });
}

/// UI model for drawing categories (used in the presentation layer)
class DrawingCategory {
  final String titleEn;
  final String titleDe;
  final String? descriptionEn;
  final String? descriptionDe;
  final String icon;
  final Color color;
  final List<Drawing> drawings;

  const DrawingCategory({
    required this.titleEn,
    required this.titleDe,
    this.descriptionEn,
    this.descriptionDe,
    required this.icon,
    required this.color,
    required this.drawings,
  });
}
