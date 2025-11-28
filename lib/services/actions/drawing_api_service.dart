import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

  /// Edit an image with AI using a text prompt
  /// Supports two modes:
  /// 1. Upload a new image file (imageFile provided)
  /// 2. Re-edit an existing image from Spaces (imageUrl provided)
  ///
  /// [imageFile] - The image file to edit (optional if imageUrl is provided)
  /// [imageUrl] - URL of existing image from Spaces to re-edit (optional if imageFile is provided)
  /// [prompt] - The editing instruction (e.g., "make it alive", "make it colorful")
  /// [subject] - What the child drew (e.g., 'dog', 'cat') - helps Gemini understand the drawing
  /// [drawingId] - UUID of existing drawing to append edit to (optional for re-editing)
  ///
  /// Returns [ApiImageEditResponse] with the edited image URLs
  /// Throws [ApiException] on error
  static Future<ApiImageEditResponse> editImage({
    File? imageFile,
    String? imageUrl,
    required String prompt,
    String? subject,
    String? drawingId,
  }) async {
    return await BaseApiService.handleApiCall<ApiImageEditResponse>(() async {
      print('🎨 Starting image edit request');
      print(
        '📁 Image file: ${imageFile?.path ?? "No image file re-edit with image URL: $imageUrl"}',
      );
      print('💬 Option: $prompt');

      // Validate that either imageFile or imageUrl is provided
      if (imageFile == null && imageUrl == null) {
        print('❌ Either imageFile or imageUrl must be provided!');
        throw ApiException('Either image file or image URL must be provided');
      }

      if (prompt.trim().isEmpty) {
        print('❌ Option is empty!');
        throw ApiException('Option cannot be empty');
      }

      print('✅ Validation passed, making API request...');

      // Prepare request fields
      final fields = {'prompt': prompt.trim()};

      // Add subject if provided (helps Gemini understand the drawing)
      if (subject != null && subject.trim().isNotEmpty) {
        fields['subject'] = subject.trim();
        print('📚 Subject Added to the request: $subject');
      }

      // Add drawingId if provided (for appending to existing drawing)
      if (drawingId != null) {
        fields['drawing_id'] = drawingId;
        print('📝 Drawing ID: $drawingId (appending to existing drawing)');
      }

      // Make multipart API request
      if (imageFile != null) {
        // New upload: send file
        print('📁 Image file: ${imageFile.path}');

        if (!imageFile.existsSync()) {
          print('❌ Image file does not exist!');
          throw ApiException('Image file does not exist');
        }

        final response = await BaseApiService.postMultipart(
          '/api/edit-image',
          file: imageFile,
          fileFieldName: 'image',
          fields: fields,
        );

        print('🎉 API request completed');

        // Handle response
        final jsonData = BaseApiService.handleResponse(response);
        final result = ApiImageEditResponse.fromJson(jsonData);

        print(
          '✅ Image edited successfully! Processing time: ${result.processingTime}s',
        );

        return result;
      } else {
        // Re-editing: send URL
        print('🔄 Re-editing image from URL: $imageUrl');
        fields['image_url'] = imageUrl!;

        final response = await BaseApiService.postMultipart(
          '/api/edit-image',
          fields: fields,
        );

        print('🎉 API request completed');

        // Handle response
        final jsonData = BaseApiService.handleResponse(response);
        final result = ApiImageEditResponse.fromJson(jsonData);

        print(
          '✅ Image edited successfully! Processing time: ${result.processingTime}s',
        );

        return result;
      }
    });
  }

  /// Create a story from an image
  /// Supports two modes:
  /// 1. Upload image data directly (imageData provided as File or Uint8List)
  /// 2. Use image URL from Spaces (imageUrl provided)
  /// Language parameter: 'en' for English or 'de' for German
  static Future<ApiStoryResponse> createStory({
    dynamic
    imageData, // Can be File or Uint8List (optional if imageUrl provided)
    String?
    imageUrl, // URL of image from Spaces (optional if imageData provided)
    required String language, // 'en' or 'de'
    String? drawingId, // Optional drawing ID for linking story to drawing
  }) async {
    return await BaseApiService.handleApiCall<ApiStoryResponse>(() async {
      print('📖 Starting story creation...');
      print('   Language: $language');

      // Prepare request body
      final body = <String, dynamic>{'language': language};

      // Add image data or URL
      if (imageUrl != null) {
        print('🔗 Using image URL from Spaces');
        print('   URL: $imageUrl');
        body['image_url'] = imageUrl;
      } else if (imageData != null) {
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

        print('📤 Image converted to base64');
        print('   Image size: ${base64Image.length} characters');
        body['image'] = base64Image;
      } else {
        throw Exception('Either imageData or imageUrl must be provided');
      }

      // Add drawing ID if provided
      if (drawingId != null) {
        print('📝 Linking story to drawing: $drawingId');
        body['drawing_id'] = drawingId;
      }

      print('📤 Sending story creation request...');

      final response = await BaseApiService.post(
        '/api/create-story',
        body: body,
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

  /// Edit an image with AI using both a text prompt and voice input
  /// The voice input provides additional context for the AI to enhance the image
  /// Supports two modes:
  /// 1. Upload a new image file (imageFile provided)
  /// 2. Re-edit an existing image from Spaces (imageUrl provided)
  ///
  /// [imageFile] - The image file to edit (optional if imageUrl is provided)
  /// [imageUrl] - URL of existing image from Spaces to re-edit (optional if imageFile is provided)
  /// [audioBytes] - Raw audio data (AAC format recommended, no disk I/O needed)
  /// [language] - Language code: 'en' for English or 'de' for German
  /// [subject] - What the child drew (e.g., 'dog', 'cat') - helps Gemini understand the drawing
  /// [drawingId] - UUID of existing drawing to append edit to (optional for re-editing)
  ///
  /// Returns [ApiImageEditResponse] with the edited image URLs
  /// Throws [ApiException] on error
  static Future<ApiImageEditResponse> editImageWithVoice({
    File? imageFile,
    String? imageUrl,
    required Uint8List audioBytes,
    required String language,
    String? subject,
    String? drawingId,
  }) async {
    return await BaseApiService.handleApiCall<ApiImageEditResponse>(() async {
      print('🎨 Starting image edit with voice request');
      print('🎤 Audio data: ${audioBytes.length} bytes');
      print('💬 Language: $language');

      // Validate that either imageFile or imageUrl is provided
      if (imageFile == null && imageUrl == null) {
        print('❌ Either imageFile or imageUrl must be provided!');
        throw ApiException('Either image file or image URL must be provided');
      }

      if (audioBytes.isEmpty) {
        print('❌ Audio data is empty!');
        throw ApiException('Audio data cannot be empty');
      }

      // Validate language code
      if (language != 'en' && language != 'de') {
        print('❌ Invalid language code: $language');
        throw ApiException('Language must be "en" or "de"');
      }

      print('✅ All validations passed');

      // Prepare base fields
      final fields = {
        'language': language, // Language ('en' or 'de')
      };

      // Add subject if provided (helps Gemini understand the drawing)
      if (subject != null && subject.trim().isNotEmpty) {
        fields['subject'] = subject.trim();
        print('📚 Subject Added to the request: $subject');
      }

      // Add drawingId if provided (for appending to existing drawing)
      if (drawingId != null) {
        fields['drawing_id'] = drawingId;
        print('📝 Drawing ID: $drawingId (appending to existing drawing)');
      }

      // Make multipart API request with audio and either image file or URL
      late final http.Response response;

      if (imageFile != null) {
        // New upload: send file with audio
        print('📁 Image file: ${imageFile.path}');

        if (!imageFile.existsSync()) {
          print('❌ Image file does not exist!');
          throw ApiException('Image file does not exist');
        }

        // Audio bytes are sent directly without saving to disk (memory efficient)
        response = await BaseApiService.postMultipartWithAudio(
          '/api/edit-image-with-audio',
          imageFile: imageFile,
          imageFieldName: 'image', // Form field name for the image
          audioBytes: audioBytes,
          audioFieldName: 'audio', // Form field name for the audio
          audioFormat: 'aac', // Audio format
          fields: fields,
        );
      } else {
        // Re-editing: send URL with audio
        print('🔄 Re-editing image from URL: $imageUrl');
        fields['image_url'] = imageUrl!;

        // Create multipart request with audio and URL field
        final url = Uri.parse(
          '${BaseApiService.baseUrl}/api/edit-image-with-audio',
        );
        final request = http.MultipartRequest('POST', url);

        // Add auth token if available
        final authToken = BaseApiService.getAuthToken();
        if (authToken != null) {
          request.headers['Authorization'] = 'Bearer $authToken';
        }

        // Add audio bytes
        final audioMultipartFile = http.MultipartFile(
          'audio',
          Stream.value(audioBytes),
          audioBytes.length,
          filename: 'audio.aac',
          contentType: MediaType.parse('audio/aac'),
        );
        request.files.add(audioMultipartFile);
        print('🎤 Audio added to request (${audioBytes.length} bytes)');

        // Add fields
        request.fields.addAll(fields);
        print('📋 Fields: $fields');

        print('🚀 Sending multipart request to: $url');

        // Send request
        final streamedResponse = await request.send().timeout(
          BaseApiService.timeout,
        );
        print('📥 Response status: ${streamedResponse.statusCode}');

        // Convert streamed response to regular response
        response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode >= 400) {
          print('❌ Error response: ${response.body}');
        } else {
          print('✅ Success response received');
        }
      }

      print('🎉 API request completed');

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);
      final result = ApiImageEditResponse.fromJson(jsonData);

      print(
        '✅ Image edited with voice successfully! Processing time: ${result.processingTime}s',
      );

      return result;
    });
  }

  /// Get all categories with their nested drawings
  ///
  /// Fetches all available drawing categories from the backend with complete
  /// drawing information for each category.
  ///
  /// Returns [List<ApiCategoryWithDrawings>] with categories and their drawings
  /// Throws [ApiException] on error
  static Future<List<ApiCategoryWithDrawings>>
  getCategoriesWithDrawings() async {
    return await BaseApiService.handleApiCall<List<ApiCategoryWithDrawings>>(
      () async {
        print('📚 Fetching categories with drawings from API');

        final response = await BaseApiService.get(
          '/api/categories-with-drawings',
        );
        final jsonData = BaseApiService.handleResponse(response);

        print('✅ Categories response received');

        // Parse the response
        final data = jsonData['data'] as List<dynamic>? ?? [];
        final categories = data
            .map(
              (item) => ApiCategoryWithDrawings.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();

        print('📦 Parsed ${categories.length} categories');

        return categories;
      },
    );
  }

  /// Get drawings for a specific category
  ///
  /// [category] - Category name (e.g., "Animals", "Nature")
  ///
  /// Returns [List<ApiDrawing>] with drawings in the category
  /// Throws [ApiException] on error
  static Future<List<ApiDrawing>> getDrawingsByCategory(String category) async {
    return await BaseApiService.handleApiCall<List<ApiDrawing>>(() async {
      if (category.trim().isEmpty) {
        throw ApiException('Category cannot be empty');
      }

      print('🎨 Fetching drawings for category: $category');

      final response = await BaseApiService.get(
        '/api/categories/${Uri.encodeComponent(category)}/drawings',
      );
      final jsonData = BaseApiService.handleResponse(response);

      print('✅ Drawings response received');

      // Parse the response (it's a list of drawings)
      final data = jsonData as List<dynamic>? ?? [];
      final drawings = data
          .map((item) => ApiDrawing.fromJson(item as Map<String, dynamic>))
          .toList();

      print('📦 Parsed ${drawings.length} drawings');

      return drawings;
    });
  }
}
