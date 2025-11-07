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
  final String stepImg; // base64 image

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
  final String resultImage; // base64 encoded edited image
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
