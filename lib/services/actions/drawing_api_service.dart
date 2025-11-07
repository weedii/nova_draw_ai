import '../../models/api_models.dart';
import 'base_api_service.dart';
import 'api_exceptions.dart';

/// API service specifically for drawing tutorial operations
class DrawingApiService {
  
  /// Generate a complete drawing tutorial from the backend API
  ///
  /// [subject] - What to draw (e.g., "cat", "dog", "butterfly")
  ///
  /// Returns [ApiDrawingStepResponse] with all steps and base64 images
  /// Throws [ApiException] on error
  static Future<ApiDrawingStepResponse> generateTutorial(String subject) async {
    return await BaseApiService.handleApiCall<ApiDrawingStepResponse>(() async {
      // Validate input
      if (subject.trim().isEmpty) {
        throw ApiException('Subject cannot be empty');
      }

      if (subject.length > 100) {
        throw ApiException('Subject name too long (max 100 characters)');
      }

      // Make API request
      final response = await BaseApiService.post(
        '/api/generate-tutorial',
        body: {'subject': subject.trim()},
      );

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);
      return ApiDrawingStepResponse.fromJson(jsonData);
    });
  }

  /// Get available drawing categories (if API supports it in the future)
  ///
  /// Returns list of available drawing categories
  /// Throws [ApiException] on error
  static Future<List<String>> getDrawingCategories() async {
    return await BaseApiService.handleApiCall<List<String>>(() async {
      final response = await BaseApiService.get('/api/drawing-categories');
      final jsonData = BaseApiService.handleResponse(response);
      
      return List<String>.from(jsonData['categories'] ?? []);
    });
  }

  /// Get suggested drawing subjects by category (if API supports it in the future)
  ///
  /// [category] - The category to get suggestions for
  ///
  /// Returns list of suggested drawing subjects
  /// Throws [ApiException] on error
  static Future<List<String>> getDrawingSuggestions(String category) async {
    return await BaseApiService.handleApiCall<List<String>>(() async {
      if (category.trim().isEmpty) {
        throw ApiException('Category cannot be empty');
      }

      final response = await BaseApiService.get('/api/drawing-suggestions?category=${Uri.encodeComponent(category)}');
      final jsonData = BaseApiService.handleResponse(response);
      
      return List<String>.from(jsonData['suggestions'] ?? []);
    });
  }

  /// Save a user's drawing progress (if API supports it in the future)
  ///
  /// [subject] - The drawing subject
  /// [stepIndex] - Current step index
  /// [userId] - User identifier
  ///
  /// Returns success status
  /// Throws [ApiException] on error
  static Future<bool> saveDrawingProgress({
    required String subject,
    required int stepIndex,
    required String userId,
  }) async {
    return await BaseApiService.handleApiCall<bool>(() async {
      if (subject.trim().isEmpty) {
        throw ApiException('Subject cannot be empty');
      }

      if (userId.trim().isEmpty) {
        throw ApiException('User ID cannot be empty');
      }

      final response = await BaseApiService.post(
        '/api/save-progress',
        body: {
          'subject': subject.trim(),
          'step_index': stepIndex,
          'user_id': userId.trim(),
        },
      );

      final jsonData = BaseApiService.handleResponse(response);
      return jsonData['success'] == true;
    });
  }

  /// Get user's drawing progress (if API supports it in the future)
  ///
  /// [userId] - User identifier
  ///
  /// Returns map of subject to step index
  /// Throws [ApiException] on error
  static Future<Map<String, int>> getUserDrawingProgress(String userId) async {
    return await BaseApiService.handleApiCall<Map<String, int>>(() async {
      if (userId.trim().isEmpty) {
        throw ApiException('User ID cannot be empty');
      }

      final response = await BaseApiService.get('/api/user-progress?user_id=${Uri.encodeComponent(userId)}');
      final jsonData = BaseApiService.handleResponse(response);
      
      final progressData = jsonData['progress'] as Map<String, dynamic>? ?? {};
      return progressData.map((key, value) => MapEntry(key, value as int));
    });
  }
}
