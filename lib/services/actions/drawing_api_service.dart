import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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

      final response = await BaseApiService.get(
        '/api/drawing-suggestions?category=${Uri.encodeComponent(category)}',
      );
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

      final response = await BaseApiService.get(
        '/api/user-progress?user_id=${Uri.encodeComponent(userId)}',
      );
      final jsonData = BaseApiService.handleResponse(response);

      final progressData = jsonData['progress'] as Map<String, dynamic>? ?? {};
      return progressData.map((key, value) => MapEntry(key, value as int));
    });
  }

  /// Edit an uploaded image with AI using a text prompt
  ///
  /// [imageFile] - The image file to edit
  /// [prompt] - The editing instruction (e.g., "make it alive", "make it colorful")
  ///
  /// Returns [ApiImageEditResponse] with the edited image as base64
  /// Throws [ApiException] on error
  static Future<ApiImageEditResponse> editImage({
    required File imageFile,
    required String prompt,
  }) async {
    return await BaseApiService.handleApiCall<ApiImageEditResponse>(() async {
      print('🎨 Starting image edit request');
      print('📁 Image file: ${imageFile.path}');
      print('💬 Option: $prompt');

      // Validate input
      if (!imageFile.existsSync()) {
        print('❌ Image file does not exist!');
        throw ApiException('Image file does not exist');
      }

      if (prompt.trim().isEmpty) {
        print('❌ Option is empty!');
        throw ApiException('Option cannot be empty');
      }

      print('✅ Validation passed, making API request...');

      // Make multipart API request
      final response = await BaseApiService.postMultipart(
        '/api/edit-image',
        file: imageFile,
        fileFieldName: 'file',
        fields: {'prompt': prompt.trim()},
      );

      print('🎉 API request completed');

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);
      final result = ApiImageEditResponse.fromJson(jsonData);

      print(
        '✅ Image edited successfully! Processing time: ${result.processingTime}s',
      );

      return result;
    });
  }

  /// Create a story from an image
  /// Takes either a File or Uint8List and generates a children's story
  /// Language parameter: 'en' for English or 'de' for German
  static Future<ApiStoryResponse> createStory({
    required dynamic imageData, // Can be File or Uint8List
    required String language, // 'en' or 'de'
  }) async {
    return await BaseApiService.handleApiCall<ApiStoryResponse>(() async {
      print('📖 Starting story creation...');
      print('   Language: $language');

      // Convert image to base64
      String base64Image;
      if (imageData is File) {
        print('📁 Converting File to base64...');
        final bytes = await imageData.readAsBytes();
        base64Image = base64Encode(bytes);
      } else if (imageData is Uint8List) {
        print('📦 Converting Uint8List to base64...');
        base64Image = base64Encode(imageData);
      } else {
        throw Exception('Invalid image data type. Must be File or Uint8List');
      }

      print('📤 Sending story creation request...');
      print('   Image size: ${base64Image.length} characters');

      final response = await BaseApiService.post(
        '/api/create-story',
        body: {'image': base64Image, 'language': language},
      );

      final jsonData = BaseApiService.handleResponse(response);
      final result = ApiStoryResponse.fromJson(jsonData);

      print('✅ Story created successfully!');
      print('   Title: ${result.title}');
      print('   Story length: ${result.story.length} characters');
      if (result.generationTime != null) {
        print('   Generation time: ${result.generationTime}s');
      }

      return result;
    });
  }
}
