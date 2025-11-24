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
  final String subject;
  final int totalSteps;

  const ApiMetadata({required this.subject, required this.totalSteps});

  factory ApiMetadata.fromJson(Map<String, dynamic> json) {
    return ApiMetadata(
      subject: json['subject'] ?? '',
      totalSteps: json['total_steps'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'subject': subject, 'total_steps': totalSteps};
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
  final String resultImage; // Image URL (public URL or link)
  final double processingTime;

  const ApiImageEditResponse({
    required this.success,
    required this.prompt,
    required this.resultImage,
    required this.processingTime,
  });

  factory ApiImageEditResponse.fromJson(Map<String, dynamic> json) {
    return ApiImageEditResponse(
      success: json['success'] == 'true' || json['success'] == true,
      prompt: json['prompt'] ?? '',
      resultImage: json['result_image'] ?? '',
      processingTime: (json['processing_time'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success.toString(),
      'prompt': prompt,
      'result_image': resultImage,
      'processing_time': processingTime,
    };
  }
}

/// API response model for story generation
class ApiStoryResponse {
  final String success;
  final String story;
  final String title;
  final double? generationTime;

  ApiStoryResponse({
    required this.success,
    required this.story,
    required this.title,
    this.generationTime,
  });

  factory ApiStoryResponse.fromJson(Map<String, dynamic> json) {
    return ApiStoryResponse(
      success: json['success'] as String,
      story: json['story'] as String,
      title: json['title'] as String,
      generationTime: json['generation_time'] != null
          ? (json['generation_time'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'story': story,
      'title': title,
      'generation_time': generationTime,
    };
  }
}

/// API response model for edit options
class ApiEditOption {
  final String id;
  final String category;
  final String subject;
  final String titleEn;
  final String titleDe;
  final String descriptionEn;
  final String descriptionDe;
  final String promptEn;
  final String promptDe;
  final String? icon;

  const ApiEditOption({
    required this.id,
    required this.category,
    required this.subject,
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
      category: json['category'] ?? '',
      subject: json['subject'] ?? '',
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
      'category': category,
      'subject': subject,
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
  final String nameEn;
  final String nameDe;
  final String emoji;
  final int totalSteps;
  final String? thumbnailUrl;
  final String? descriptionEn;
  final String? descriptionDe;

  const ApiDrawing({
    required this.nameEn,
    required this.nameDe,
    required this.emoji,
    required this.totalSteps,
    this.thumbnailUrl,
    this.descriptionEn,
    this.descriptionDe,
  });

  factory ApiDrawing.fromJson(Map<String, dynamic> json) {
    return ApiDrawing(
      nameEn: json['name_en'] ?? '',
      nameDe: json['name_de'] ?? '',
      emoji: json['emoji'],
      totalSteps: json['total_steps'] ?? 0,
      thumbnailUrl: json['thumbnail_url'],
      descriptionEn: json['description_en'],
      descriptionDe: json['description_de'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name_en': nameEn,
      'name_de': nameDe,
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
  final String titleEn;
  final String titleDe;
  final String? descriptionEn;
  final String? descriptionDe;
  final String emoji;
  final String color;
  final List<ApiDrawing> drawings;

  const ApiCategoryWithDrawings({
    required this.titleEn,
    required this.titleDe,
    this.descriptionEn,
    this.descriptionDe,
    required this.emoji,
    required this.color,
    required this.drawings,
  });

  factory ApiCategoryWithDrawings.fromJson(Map<String, dynamic> json) {
    return ApiCategoryWithDrawings(
      titleEn: json['title_en'] ?? '',
      titleDe: json['title_de'] ?? '',
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
      'title_en': titleEn,
      'title_de': titleDe,
      'description_en': descriptionEn,
      'description_de': descriptionDe,
      'emoji': emoji,
      'color': color,
      'drawings': drawings.map((d) => d.toJson()).toList(),
    };
  }
}
