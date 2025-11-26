class ApiDrawingStepResponse {
  final bool success;
  final ApiMetadata metadata;
  final List<ApiDrawingStep> steps;

  const ApiDrawingStepResponse({
    required this.success,
    required this.metadata,
    required this.steps,
  });

  factory ApiDrawingStepResponse.fromJson(Map<String, dynamic> json) {
    return ApiDrawingStepResponse(
      success: json['success'] == 'true' || json['success'] == true,
      metadata: ApiMetadata.fromJson(json['metadata']),
      steps: (json['steps'] as List)
          .map((step) => ApiDrawingStep.fromJson(step))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success.toString(),
      'metadata': metadata.toJson(),
      'steps': steps.map((step) => step.toJson()).toList(),
    };
  }
}

class ApiMetadata {
  final String subjectEn;
  final String subjectDe;
  final int totalSteps;

  const ApiMetadata({
    required this.subjectEn,
    required this.subjectDe,
    required this.totalSteps,
  });

  factory ApiMetadata.fromJson(Map<String, dynamic> json) {
    return ApiMetadata(
      subjectEn: json['subject_en'] ?? '',
      subjectDe: json['subject_de'] ?? '',
      totalSteps: json['total_steps'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_en': subjectEn,
      'subject_de': subjectDe,
      'total_steps': totalSteps,
    };
  }
}

class ApiDrawingStep {
  final String stepEn;
  final String stepDe;
  final String stepImg; // Image URL (public URL or link)

  const ApiDrawingStep({
    required this.stepEn,
    required this.stepDe,
    required this.stepImg,
  });

  factory ApiDrawingStep.fromJson(Map<String, dynamic> json) {
    return ApiDrawingStep(
      stepEn: json['step_en'] ?? '',
      stepDe: json['step_de'] ?? '',
      stepImg: json['step_img'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'step_en': stepEn, 'step_de': stepDe, 'step_img': stepImg};
  }
}

class ApiImageEditResponse {
  final bool success;
  final String prompt;
  final String? originalImageUrl; // URL of the original uploaded image
  final String? editedImageUrl; // URL of the edited image
  final double processingTime;
  final String? drawingId; // ID of the saved drawing in database
  final String? userId; // ID of the user who created the drawing

  const ApiImageEditResponse({
    required this.success,
    required this.prompt,
    this.originalImageUrl,
    this.editedImageUrl,
    required this.processingTime,
    this.drawingId,
    this.userId,
  });

  factory ApiImageEditResponse.fromJson(Map<String, dynamic> json) {
    return ApiImageEditResponse(
      success: json['success'] == 'true' || json['success'] == true,
      prompt: json['prompt'] ?? '',
      originalImageUrl: json['original_image_url'],
      editedImageUrl: json['edited_image_url'],
      processingTime: (json['processing_time'] ?? 0.0).toDouble(),
      drawingId: json['drawing_id'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success.toString(),
      'prompt': prompt,
      'original_image_url': originalImageUrl,
      'edited_image_url': editedImageUrl,
      'processing_time': processingTime,
      'drawing_id': drawingId,
      'user_id': userId,
    };
  }
}

/// API response model for story generation
class ApiStoryResponse {
  final String success;
  final String story;
  final String title;
  final double? generationTime;
  final String? imageUrl;

  ApiStoryResponse({
    required this.success,
    required this.story,
    required this.title,
    this.generationTime,
    this.imageUrl,
  });

  factory ApiStoryResponse.fromJson(Map<String, dynamic> json) {
    return ApiStoryResponse(
      success: json['success'] as String,
      story: json['story'] as String,
      title: json['title'] as String,
      generationTime: json['generation_time'] != null
          ? (json['generation_time'] as num).toDouble()
          : null,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'story': story,
      'title': title,
      'generation_time': generationTime,
      'image_url': imageUrl,
    };
  }
}

/// API response model for edit options
class ApiEditOption {
  final String id;
  final String tutorialId;
  final String titleEn;
  final String titleDe;
  final String descriptionEn;
  final String descriptionDe;
  final String promptEn;
  final String promptDe;
  final String? icon;

  const ApiEditOption({
    required this.id,
    required this.tutorialId,
    required this.titleEn,
    required this.titleDe,
    required this.descriptionEn,
    required this.descriptionDe,
    required this.promptEn,
    required this.promptDe,
    this.icon,
  });

  factory ApiEditOption.fromJson(Map<String, dynamic> json) {
    return ApiEditOption(
      id: json['id'] ?? '',
      tutorialId: json['tutorial_id'] ?? '',
      titleEn: json['title_en'] ?? '',
      titleDe: json['title_de'] ?? '',
      descriptionEn: json['description_en'] ?? '',
      descriptionDe: json['description_de'] ?? '',
      promptEn: json['prompt_en'] ?? '',
      promptDe: json['prompt_de'] ?? '',
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tutorial_id': tutorialId,
      'title_en': titleEn,
      'title_de': titleDe,
      'description_en': descriptionEn,
      'description_de': descriptionDe,
      'prompt_en': promptEn,
      'prompt_de': promptDe,
      'icon': icon,
    };
  }
}

/// API model for drawing/subject data
class ApiDrawing {
  final String subjectEn;
  final String subjectDe;
  final String emoji;
  final int totalSteps;
  final String? thumbnailUrl;
  final String? descriptionEn;
  final String? descriptionDe;

  const ApiDrawing({
    required this.subjectEn,
    required this.subjectDe,
    required this.emoji,
    required this.totalSteps,
    this.thumbnailUrl,
    this.descriptionEn,
    this.descriptionDe,
  });

  factory ApiDrawing.fromJson(Map<String, dynamic> json) {
    return ApiDrawing(
      subjectEn: json['subject_en'] ?? '',
      subjectDe: json['subject_de'] ?? '',
      emoji: json['emoji'],
      totalSteps: json['total_steps'] ?? 0,
      thumbnailUrl: json['thumbnail_url'],
      descriptionEn: json['description_en'],
      descriptionDe: json['description_de'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_en': subjectEn,
      'subject_de': subjectDe,
      'emoji': emoji,
      'total_steps': totalSteps,
      'thumbnail_url': thumbnailUrl,
      'description_en': descriptionEn,
      'description_de': descriptionDe,
    };
  }
}

/// API model for category with nested drawings
class ApiCategoryWithDrawings {
  final String categoryEn;
  final String categoryDe;
  final String? descriptionEn;
  final String? descriptionDe;
  final String emoji;
  final String color;
  final List<ApiDrawing> drawings;

  const ApiCategoryWithDrawings({
    required this.categoryEn,
    required this.categoryDe,
    this.descriptionEn,
    this.descriptionDe,
    required this.emoji,
    required this.color,
    required this.drawings,
  });

  factory ApiCategoryWithDrawings.fromJson(Map<String, dynamic> json) {
    return ApiCategoryWithDrawings(
      categoryEn: json['category_en'] ?? '',
      categoryDe: json['category_de'] ?? '',
      descriptionEn: json['description_en'],
      descriptionDe: json['description_de'],
      emoji: json['emoji'],
      color: json['color'],
      drawings:
          (json['drawings'] as List<dynamic>?)
              ?.map(
                (drawing) =>
                    ApiDrawing.fromJson(drawing as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_en': categoryEn,
      'category_de': categoryDe,
      'description_en': descriptionEn,
      'description_de': descriptionDe,
      'emoji': emoji,
      'color': color,
      'drawings': drawings.map((d) => d.toJson()).toList(),
    };
  }
}

/// API model for tutorial info in gallery
class ApiTutorialInfo {
  final String id;
  final String categoryEn;
  final String categoryDe;
  final String categoryEmoji;
  final String categoryColor;
  final String subjectEn;
  final String subjectDe;
  final String subjectEmoji;

  const ApiTutorialInfo({
    required this.id,
    required this.categoryEn,
    required this.categoryDe,
    required this.categoryEmoji,
    required this.categoryColor,
    required this.subjectEn,
    required this.subjectDe,
    required this.subjectEmoji,
  });

  factory ApiTutorialInfo.fromJson(Map<String, dynamic> json) {
    return ApiTutorialInfo(
      id: json['id'] ?? '',
      categoryEn: json['category_en'] ?? '',
      categoryDe: json['category_de'] ?? '',
      categoryEmoji: json['category_emoji'] ?? '🎨',
      categoryColor: json['category_color'] ?? '#FF6B6B',
      subjectEn: json['subject_en'] ?? '',
      subjectDe: json['subject_de'] ?? '',
      subjectEmoji: json['subject_emoji'] ?? '✏️',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_en': categoryEn,
      'category_de': categoryDe,
      'category_emoji': categoryEmoji,
      'category_color': categoryColor,
      'subject_en': subjectEn,
      'subject_de': subjectDe,
      'subject_emoji': subjectEmoji,
    };
  }
}

/// API model for a user's gallery drawing
class ApiGalleryDrawing {
  final String id;
  final String userId;
  final String? tutorialId;
  final ApiTutorialInfo? tutorial;
  final String? uploadedImageUrl;
  final List<String>? editedImagesUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ApiGalleryDrawing({
    required this.id,
    required this.userId,
    this.tutorialId,
    this.tutorial,
    this.uploadedImageUrl,
    this.editedImagesUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiGalleryDrawing.fromJson(Map<String, dynamic> json) {
    return ApiGalleryDrawing(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      tutorialId: json['tutorial_id'],
      tutorial: json['tutorial'] != null
          ? ApiTutorialInfo.fromJson(json['tutorial'] as Map<String, dynamic>)
          : null,
      uploadedImageUrl: json['uploaded_image_url'],
      editedImagesUrls: json['edited_images_urls'] != null
          ? List<String>.from(json['edited_images_urls'] as List)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'tutorial_id': tutorialId,
      'tutorial': tutorial?.toJson(),
      'uploaded_image_url': uploadedImageUrl,
      'edited_images_urls': editedImagesUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// API response model for gallery list
class ApiGalleryListResponse {
  final bool success;
  final List<ApiGalleryDrawing> data;
  final int count;
  final int? page;
  final int? limit;

  const ApiGalleryListResponse({
    required this.success,
    required this.data,
    required this.count,
    this.page,
    this.limit,
  });

  factory ApiGalleryListResponse.fromJson(Map<String, dynamic> json) {
    return ApiGalleryListResponse(
      success: json['success'] == true || json['success'] == 'true',
      data:
          (json['data'] as List<dynamic>?)
              ?.map(
                (item) =>
                    ApiGalleryDrawing.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      count: json['count'] ?? 0,
      page: json['page'],
      limit: json['limit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((d) => d.toJson()).toList(),
      'count': count,
      'page': page,
      'limit': limit,
    };
  }
}
