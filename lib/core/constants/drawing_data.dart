import 'package:flutter/material.dart';
import 'colors.dart';

class DrawingItem {
  final String id;
  final String nameKey;
  final String emoji;
  final String description;
  final int difficulty; // 1-3 (easy, medium, hard)
  final List<DrawingStep> steps;

  const DrawingItem({
    required this.id,
    required this.nameKey,
    required this.emoji,
    required this.description,
    required this.difficulty,
    required this.steps,
  });
}

class DrawingStep {
  final int stepNumber;
  final String titleKey;
  final String descriptionKey;
  final String imageUrl;

  const DrawingStep({
    required this.stepNumber,
    required this.titleKey,
    required this.descriptionKey,
    required this.imageUrl,
  });
}

class DrawingCategory {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final String icon;
  final Color color;
  final List<DrawingItem> items;

  const DrawingCategory({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
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
      titleKey: 'animals',
      descriptionKey: 'animals_description',
      icon: '🐶',
      color: AppColors.primary,
      items: [
        DrawingItem(
          id: 'dog',
          nameKey: 'dog',
          emoji: '🐕',
          description: 'A friendly dog with floppy ears',
          difficulty: 2,
          steps: [
            DrawingStep(
              stepNumber: 1,
              titleKey: 'draw_circle_head',
              descriptionKey: 'draw_circle_head_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/4DA6FF/FFFFFF?text=Dog+Head',
            ),
            DrawingStep(
              stepNumber: 2,
              titleKey: 'add_ears',
              descriptionKey: 'add_ears_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FF7EB9/FFFFFF?text=Dog+Ears',
            ),
            DrawingStep(
              stepNumber: 3,
              titleKey: 'draw_body',
              descriptionKey: 'draw_body_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FFD93D/FFFFFF?text=Dog+Body',
            ),
            DrawingStep(
              stepNumber: 4,
              titleKey: 'add_legs_tail',
              descriptionKey: 'add_legs_tail_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/7CFFCB/FFFFFF?text=Dog+Complete',
            ),
          ],
        ),
        DrawingItem(
          id: 'cat',
          nameKey: 'cat',
          emoji: '🐱',
          description: 'A cute cat with pointy ears',
          difficulty: 2,
          steps: [
            DrawingStep(
              stepNumber: 1,
              titleKey: 'draw_circle_head',
              descriptionKey: 'draw_circle_head_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/4DA6FF/FFFFFF?text=Cat+Head',
            ),
            DrawingStep(
              stepNumber: 2,
              titleKey: 'add_triangle_ears',
              descriptionKey: 'add_triangle_ears_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FF7EB9/FFFFFF?text=Cat+Ears',
            ),
            DrawingStep(
              stepNumber: 3,
              titleKey: 'draw_oval_body',
              descriptionKey: 'draw_oval_body_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FFD93D/FFFFFF?text=Cat+Body',
            ),
            DrawingStep(
              stepNumber: 4,
              titleKey: 'add_face_details',
              descriptionKey: 'add_face_details_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/7CFFCB/FFFFFF?text=Cat+Complete',
            ),
          ],
        ),
        DrawingItem(
          id: 'fish',
          nameKey: 'fish',
          emoji: '🐠',
          description: 'A colorful fish swimming',
          difficulty: 1,
          steps: [
            DrawingStep(
              stepNumber: 1,
              titleKey: 'draw_oval_body',
              descriptionKey: 'draw_oval_body_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/4DA6FF/FFFFFF?text=Fish+Body',
            ),
            DrawingStep(
              stepNumber: 2,
              titleKey: 'add_tail_fin',
              descriptionKey: 'add_tail_fin_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FF7EB9/FFFFFF?text=Fish+Tail',
            ),
            DrawingStep(
              stepNumber: 3,
              titleKey: 'add_fins_eye',
              descriptionKey: 'add_fins_eye_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/7CFFCB/FFFFFF?text=Fish+Complete',
            ),
          ],
        ),
        DrawingItem(
          id: 'elephant',
          nameKey: 'elephant',
          emoji: '🐘',
          description: 'A big elephant with a long trunk',
          difficulty: 3,
          steps: [
            DrawingStep(
              stepNumber: 1,
              titleKey: 'draw_large_circle',
              descriptionKey: 'draw_large_circle_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/4DA6FF/FFFFFF?text=Elephant+Head',
            ),
            DrawingStep(
              stepNumber: 2,
              titleKey: 'add_trunk',
              descriptionKey: 'add_trunk_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FF7EB9/FFFFFF?text=Elephant+Trunk',
            ),
            DrawingStep(
              stepNumber: 3,
              titleKey: 'draw_large_body',
              descriptionKey: 'draw_large_body_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FFD93D/FFFFFF?text=Elephant+Body',
            ),
            DrawingStep(
              stepNumber: 4,
              titleKey: 'add_legs_ears',
              descriptionKey: 'add_legs_ears_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/7CFFCB/FFFFFF?text=Elephant+Complete',
            ),
          ],
        ),
      ],
    ),

    // Objects Category
    DrawingCategory(
      id: 'objects',
      titleKey: 'objects',
      descriptionKey: 'objects_description',
      icon: '⚽',
      color: AppColors.accent,
      items: [
        DrawingItem(
          id: 'house',
          nameKey: 'house',
          emoji: '🏠',
          description: 'A cozy house with a roof',
          difficulty: 2,
          steps: [
            DrawingStep(
              stepNumber: 1,
              titleKey: 'draw_square_base',
              descriptionKey: 'draw_square_base_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FF7EB9/FFFFFF?text=House+Base',
            ),
            DrawingStep(
              stepNumber: 2,
              titleKey: 'add_triangle_roof',
              descriptionKey: 'add_triangle_roof_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FFD93D/FFFFFF?text=House+Roof',
            ),
            DrawingStep(
              stepNumber: 3,
              titleKey: 'add_door_windows',
              descriptionKey: 'add_door_windows_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/7CFFCB/FFFFFF?text=House+Complete',
            ),
          ],
        ),
        DrawingItem(
          id: 'ball',
          nameKey: 'ball',
          emoji: '⚽',
          description: 'A round ball for playing',
          difficulty: 1,
          steps: [
            DrawingStep(
              stepNumber: 1,
              titleKey: 'draw_perfect_circle',
              descriptionKey: 'draw_perfect_circle_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FF7EB9/FFFFFF?text=Ball+Circle',
            ),
            DrawingStep(
              stepNumber: 2,
              titleKey: 'add_pattern_lines',
              descriptionKey: 'add_pattern_lines_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/7CFFCB/FFFFFF?text=Ball+Complete',
            ),
          ],
        ),
        DrawingItem(
          id: 'star',
          nameKey: 'star',
          emoji: '⭐',
          description: 'A bright shining star',
          difficulty: 2,
          steps: [
            DrawingStep(
              stepNumber: 1,
              titleKey: 'draw_star_points',
              descriptionKey: 'draw_star_points_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FF7EB9/FFFFFF?text=Star+Points',
            ),
            DrawingStep(
              stepNumber: 2,
              titleKey: 'connect_star_lines',
              descriptionKey: 'connect_star_lines_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FFD93D/FFFFFF?text=Star+Lines',
            ),
            DrawingStep(
              stepNumber: 3,
              titleKey: 'add_sparkles',
              descriptionKey: 'add_sparkles_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/7CFFCB/FFFFFF?text=Star+Complete',
            ),
          ],
        ),
      ],
    ),

    // Nature Category
    DrawingCategory(
      id: 'nature',
      titleKey: 'nature',
      descriptionKey: 'nature_description',
      icon: '🌳',
      color: AppColors.success,
      items: [
        DrawingItem(
          id: 'tree',
          nameKey: 'tree',
          emoji: '🌳',
          description: 'A tall tree with leaves',
          difficulty: 2,
          steps: [
            DrawingStep(
              stepNumber: 1,
              titleKey: 'draw_trunk',
              descriptionKey: 'draw_trunk_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/7CFFCB/FFFFFF?text=Tree+Trunk',
            ),
            DrawingStep(
              stepNumber: 2,
              titleKey: 'add_branches',
              descriptionKey: 'add_branches_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/4DA6FF/FFFFFF?text=Tree+Branches',
            ),
            DrawingStep(
              stepNumber: 3,
              titleKey: 'add_leaves',
              descriptionKey: 'add_leaves_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FFD93D/FFFFFF?text=Tree+Complete',
            ),
          ],
        ),
        DrawingItem(
          id: 'flower',
          nameKey: 'flower',
          emoji: '🌸',
          description: 'A beautiful flower with petals',
          difficulty: 2,
          steps: [
            DrawingStep(
              stepNumber: 1,
              titleKey: 'draw_flower_center',
              descriptionKey: 'draw_flower_center_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/7CFFCB/FFFFFF?text=Flower+Center',
            ),
            DrawingStep(
              stepNumber: 2,
              titleKey: 'add_petals',
              descriptionKey: 'add_petals_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FF7EB9/FFFFFF?text=Flower+Petals',
            ),
            DrawingStep(
              stepNumber: 3,
              titleKey: 'add_stem_leaves',
              descriptionKey: 'add_stem_leaves_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FFD93D/FFFFFF?text=Flower+Complete',
            ),
          ],
        ),
        DrawingItem(
          id: 'sun',
          nameKey: 'sun',
          emoji: '☀️',
          description: 'A bright sunny day',
          difficulty: 1,
          steps: [
            DrawingStep(
              stepNumber: 1,
              titleKey: 'draw_sun_circle',
              descriptionKey: 'draw_sun_circle_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FFD93D/FFFFFF?text=Sun+Circle',
            ),
            DrawingStep(
              stepNumber: 2,
              titleKey: 'add_sun_rays',
              descriptionKey: 'add_sun_rays_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/7CFFCB/FFFFFF?text=Sun+Complete',
            ),
          ],
        ),
      ],
    ),

    // Vehicles Category
    DrawingCategory(
      id: 'vehicles',
      titleKey: 'vehicles',
      descriptionKey: 'vehicles_description',
      icon: '🚗',
      color: AppColors.secondary,
      items: [
        DrawingItem(
          id: 'car',
          nameKey: 'car',
          emoji: '🚗',
          description: 'A fast car with wheels',
          difficulty: 2,
          steps: [
            DrawingStep(
              stepNumber: 1,
              titleKey: 'draw_car_body',
              descriptionKey: 'draw_car_body_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FFD93D/FFFFFF?text=Car+Body',
            ),
            DrawingStep(
              stepNumber: 2,
              titleKey: 'add_car_wheels',
              descriptionKey: 'add_car_wheels_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FF7EB9/FFFFFF?text=Car+Wheels',
            ),
            DrawingStep(
              stepNumber: 3,
              titleKey: 'add_car_details',
              descriptionKey: 'add_car_details_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/7CFFCB/FFFFFF?text=Car+Complete',
            ),
          ],
        ),
        DrawingItem(
          id: 'airplane',
          nameKey: 'airplane',
          emoji: '✈️',
          description: 'An airplane flying in the sky',
          difficulty: 3,
          steps: [
            DrawingStep(
              stepNumber: 1,
              titleKey: 'draw_plane_body',
              descriptionKey: 'draw_plane_body_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FFD93D/FFFFFF?text=Plane+Body',
            ),
            DrawingStep(
              stepNumber: 2,
              titleKey: 'add_wings',
              descriptionKey: 'add_wings_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/4DA6FF/FFFFFF?text=Plane+Wings',
            ),
            DrawingStep(
              stepNumber: 3,
              titleKey: 'add_tail_propeller',
              descriptionKey: 'add_tail_propeller_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/7CFFCB/FFFFFF?text=Plane+Complete',
            ),
          ],
        ),
      ],
    ),

    // Food Category
    DrawingCategory(
      id: 'food',
      titleKey: 'food',
      descriptionKey: 'food_description',
      icon: '🍎',
      color: AppColors.error,
      items: [
        DrawingItem(
          id: 'apple',
          nameKey: 'apple',
          emoji: '🍎',
          description: 'A red juicy apple',
          difficulty: 1,
          steps: [
            DrawingStep(
              stepNumber: 1,
              titleKey: 'draw_apple_shape',
              descriptionKey: 'draw_apple_shape_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FF6B6B/FFFFFF?text=Apple+Shape',
            ),
            DrawingStep(
              stepNumber: 2,
              titleKey: 'add_apple_stem',
              descriptionKey: 'add_apple_stem_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/7CFFCB/FFFFFF?text=Apple+Complete',
            ),
          ],
        ),
        DrawingItem(
          id: 'pizza',
          nameKey: 'pizza',
          emoji: '🍕',
          description: 'A delicious slice of pizza',
          difficulty: 2,
          steps: [
            DrawingStep(
              stepNumber: 1,
              titleKey: 'draw_triangle_slice',
              descriptionKey: 'draw_triangle_slice_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FF6B6B/FFFFFF?text=Pizza+Slice',
            ),
            DrawingStep(
              stepNumber: 2,
              titleKey: 'add_pizza_toppings',
              descriptionKey: 'add_pizza_toppings_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FFD93D/FFFFFF?text=Pizza+Toppings',
            ),
            DrawingStep(
              stepNumber: 3,
              titleKey: 'add_crust_details',
              descriptionKey: 'add_crust_details_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/7CFFCB/FFFFFF?text=Pizza+Complete',
            ),
          ],
        ),
      ],
    ),

    // Characters Category
    DrawingCategory(
      id: 'characters',
      titleKey: 'characters',
      descriptionKey: 'characters_description',
      icon: '👑',
      color: AppColors.primaryDark,
      items: [
        DrawingItem(
          id: 'princess',
          nameKey: 'princess',
          emoji: '👸',
          description: 'A beautiful princess with a crown',
          difficulty: 3,
          steps: [
            DrawingStep(
              stepNumber: 1,
              titleKey: 'draw_princess_head',
              descriptionKey: 'draw_princess_head_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/3D8BFF/FFFFFF?text=Princess+Head',
            ),
            DrawingStep(
              stepNumber: 2,
              titleKey: 'add_crown',
              descriptionKey: 'add_crown_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FF7EB9/FFFFFF?text=Princess+Crown',
            ),
            DrawingStep(
              stepNumber: 3,
              titleKey: 'draw_dress',
              descriptionKey: 'draw_dress_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FFD93D/FFFFFF?text=Princess+Dress',
            ),
            DrawingStep(
              stepNumber: 4,
              titleKey: 'add_face_hair',
              descriptionKey: 'add_face_hair_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/7CFFCB/FFFFFF?text=Princess+Complete',
            ),
          ],
        ),
        DrawingItem(
          id: 'robot',
          nameKey: 'robot',
          emoji: '🤖',
          description: 'A friendly robot helper',
          difficulty: 2,
          steps: [
            DrawingStep(
              stepNumber: 1,
              titleKey: 'draw_robot_head',
              descriptionKey: 'draw_robot_head_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/3D8BFF/FFFFFF?text=Robot+Head',
            ),
            DrawingStep(
              stepNumber: 2,
              titleKey: 'add_robot_body',
              descriptionKey: 'add_robot_body_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/FFD93D/FFFFFF?text=Robot+Body',
            ),
            DrawingStep(
              stepNumber: 3,
              titleKey: 'add_robot_details',
              descriptionKey: 'add_robot_details_desc',
              imageUrl:
                  'https://via.placeholder.com/300x200/7CFFCB/FFFFFF?text=Robot+Complete',
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
