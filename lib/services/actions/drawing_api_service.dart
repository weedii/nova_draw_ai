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
  /// Throws [ApiException] on error with specific error translation keys
  static Future<ApiDrawingStepResponse> generateTutorial(String subject) async {
    return await BaseApiService.handleApiCall<ApiDrawingStepResponse>(() async {
      // Validate input
      if (subject.trim().isEmpty) {
        throw ApiException('Subject cannot be empty');
      }

      if (subject.length > 100) {
        throw ApiException('Subject name too long (max 100 characters)');
      }

      print('📚 Generating tutorial for subject: $subject');

      // Make API request
      final response = await BaseApiService.post(
        '/api/generate-tutorial',
        body: {'subject': subject.trim()},
      );

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);
      final result = ApiDrawingStepResponse.fromJson(jsonData);
      print(
        '✅ Tutorial generated successfully with ${result.steps.length} steps',
      );
      return result;
    }).catchError((error) {
      if (error is ApiException) {
        // Check status code and error message to map to correct translation key
        if (error.statusCode == 404) {
          if (error.message.contains('not found')) {
            throw ApiException('drawing_steps.error_subject_not_found');
          } else if (error.message.contains('No steps')) {
            throw ApiException('drawing_steps.error_no_steps');
          }
        } else if (error.statusCode == 500) {
          throw ApiException('drawing_steps.error_server');
        }
      }
      // For any other error, throw generic error
      throw ApiException('drawing_steps.error_unknown');
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
  /// [tutorialId] - UUID of the tutorial associated with this drawing (optional)
  /// [drawingId] - UUID of existing drawing to append edit to (optional for re-editing)
  ///
  /// Returns [ApiImageEditResponse] with the edited image URLs
  /// Throws [ApiException] on error with specific error translation keys
  static Future<ApiImageEditResponse> editImage({
    File? imageFile,
    String? imageUrl,
    required String prompt,
    String? subject,
    String? tutorialId,
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
        throw ApiException('image_edit.error_no_image');
      }

      if (prompt.trim().isEmpty) {
        print('❌ Option is empty!');
        throw ApiException('image_edit.error_invalid_prompt');
      }

      print('✅ Validation passed, making API request...');

      // Prepare request fields
      final fields = {'prompt': prompt.trim()};

      // Add subject if provided (helps Gemini understand the drawing)
      if (subject != null && subject.trim().isNotEmpty) {
        fields['subject'] = subject.trim();
        print('📚 Subject Added to the request: $subject');
      }

      // Add tutorialId if provided (for database linking)
      if (tutorialId != null && tutorialId.trim().isNotEmpty) {
        fields['tutorial_id'] = tutorialId.trim();
        print('📚 Tutorial ID: $tutorialId (for database linking)');
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
          throw ApiException('image_edit.error_no_image');
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
    }).catchError((error) {
      if (error is ApiException) {
        // Check status code and error message to map to correct translation key
        if (error.statusCode == 400) {
          if (error.message.contains('image')) {
            throw ApiException('image_edit.error_invalid_image');
          } else if (error.message.contains('prompt')) {
            throw ApiException('image_edit.error_invalid_prompt');
          }
        } else if (error.statusCode == 503) {
          throw ApiException('image_edit.error_service_unavailable');
        } else if (error.statusCode == 500) {
          throw ApiException('image_edit.error_server');
        }
      }
      // For any other error, throw generic error
      throw ApiException('image_edit.error_unknown');
    });
  }

  /// Create a story from an image
  /// Supports two modes:
  /// 1. Upload image data directly (imageData provided as File or Uint8List)
  /// 2. Use image URL from Spaces (imageUrl provided)
  /// Stories are always generated in both English and German.
  /// Throws [ApiException] on error with specific error translation keys
  static Future<ApiStoryResponse> createStory({
    dynamic
    imageData, // Can be File or Uint8List (optional if imageUrl provided)
    String?
    imageUrl, // URL of image from Spaces (optional if imageData provided)
    String? drawingId, // Optional drawing ID for linking story to drawing
  }) async {
    return await BaseApiService.handleApiCall<ApiStoryResponse>(() async {
      print('📖 Starting story creation (bilingual EN + DE)...');

      // Validate that either imageData or imageUrl is provided
      if (imageData == null && imageUrl == null) {
        print('❌ Either imageData or imageUrl must be provided!');
        throw ApiException('story.error_no_image');
      }

      // Prepare request body
      final body = <String, dynamic>{};

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
          throw ApiException('story.error_invalid_image');
        }

        print('📤 Image converted to base64');
        print('   Image size: ${base64Image.length} characters');
        body['image'] = base64Image;
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
      print('   Title EN: ${result.titleEn}');
      print('   Title DE: ${result.titleDe}');
      print('   EN length: ${result.storyTextEn.length} characters');
      print('   DE length: ${result.storyTextDe.length} characters');
      if (result.generationTime != null) {
        print('   Generation time: ${result.generationTime}s');
      }

      return result;
    }).catchError((error) {
      if (error is ApiException) {
        // Check status code and error message to map to correct translation key
        if (error.statusCode == 400) {
          if (error.message.contains('image')) {
            throw ApiException('story.error_invalid_image');
          } else if (error.message.contains('JSON')) {
            throw ApiException('story.error_invalid_json');
          } else if (error.message.contains('content')) {
            throw ApiException('story.error_missing_content');
          }
        } else if (error.statusCode == 500) {
          throw ApiException('story.error_server');
        }
      }
      // For any other error, throw generic error
      throw ApiException('story.error_unknown');
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
  /// [tutorialId] - UUID of the tutorial associated with this drawing (optional)
  /// [drawingId] - UUID of existing drawing to append edit to (optional for re-editing)
  ///
  /// Returns [ApiImageEditResponse] with the edited image URLs
  /// Throws [ApiException] on error with specific error translation keys
  static Future<ApiImageEditResponse> editImageWithVoice({
    File? imageFile,
    String? imageUrl,
    required Uint8List audioBytes,
    required String language,
    String? subject,
    String? tutorialId,
    String? drawingId,
  }) async {
    return await BaseApiService.handleApiCall<ApiImageEditResponse>(() async {
      print('🎨 Starting image edit with voice request');
      print('🎤 Audio data: ${audioBytes.length} bytes');
      print('💬 Language: $language');

      // Validate that either imageFile or imageUrl is provided
      if (imageFile == null && imageUrl == null) {
        print('❌ Either imageFile or imageUrl must be provided!');
        throw ApiException('image_edit.error_no_image');
      }

      if (audioBytes.isEmpty) {
        print('❌ Audio data is empty!');
        throw ApiException('image_edit.error_invalid_prompt');
      }

      // Validate language code
      if (language != 'en' && language != 'de') {
        print('❌ Invalid language code: $language');
        throw ApiException('image_edit.error_invalid_prompt');
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

      // Add tutorialId if provided (for database linking)
      if (tutorialId != null && tutorialId.trim().isNotEmpty) {
        fields['tutorial_id'] = tutorialId.trim();
        print('📚 Tutorial ID: $tutorialId (for database linking)');
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
          throw ApiException('image_edit.error_no_image');
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
    }).catchError((error) {
      if (error is ApiException) {
        // Check status code and error message to map to correct translation key
        if (error.statusCode == 400) {
          if (error.message.contains('image')) {
            throw ApiException('image_edit.error_invalid_image');
          } else if (error.message.contains('audio')) {
            throw ApiException('image_edit.error_invalid_prompt');
          }
        } else if (error.statusCode == 503) {
          throw ApiException('image_edit.error_service_unavailable');
        } else if (error.statusCode == 500) {
          throw ApiException('image_edit.error_server');
        }
      }
      // For any other error, throw generic error
      throw ApiException('image_edit.error_unknown');
    });
  }

  /// Get all categories with their nested drawings
  ///
  /// Fetches all available drawing categories from the backend with complete
  /// drawing information for each category.
  ///
  /// Returns [List<ApiCategoryWithDrawings>] with categories and their drawings
  /// Throws [ApiException] on error with specific error translation keys
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
    ).catchError((error) {
      if (error is ApiException) {
        // Check status code and error message to map to correct translation key
        if (error.statusCode == 404) {
          if (error.message.contains('No tutorials')) {
            throw ApiException('categories.error_no_categories');
          }
        } else if (error.statusCode == 500) {
          throw ApiException('categories.error_server');
        }
      }
      // For any other error, throw generic error
      throw ApiException('categories.error_unknown');
    });
  }

  /// Get drawings for a specific category
  ///
  /// [category] - Category name (e.g., "Animals", "Nature")
  ///
  /// Returns [List<ApiDrawing>] with drawings in the category
  /// Throws [ApiException] on error with specific error translation keys
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
    }).catchError((error) {
      if (error is ApiException) {
        // Check status code and error message to map to correct translation key
        if (error.statusCode == 404) {
          if (error.message.contains('No drawings')) {
            throw ApiException('categories.error_no_drawings');
          }
        } else if (error.statusCode == 500) {
          throw ApiException('categories.error_server');
        }
      }
      // For any other error, throw generic error
      throw ApiException('categories.error_unknown');
    });
  }

  /// Direct upload: Upload any drawing with a text prompt
  /// For kids who want to upload drawings that don't fit tutorial categories
  ///
  /// [imageFile] - The drawing image file
  /// [subject] - What the child drew (e.g., "train", "dog", "flower")
  /// [prompt] - What to do with it (e.g., "make it fly", "add rainbow")
  ///
  /// Returns [ApiImageEditResponse] with the edited image URLs
  /// Throws [ApiException] on error
  static Future<ApiImageEditResponse> directUpload({
    required File imageFile,
    required String subject,
    required String prompt,
  }) async {
    return await BaseApiService.handleApiCall<ApiImageEditResponse>(() async {
      print('🎨 Starting direct upload request');
      print('📁 Image file: ${imageFile.path}');
      print('🏷️ Subject: $subject');
      print('💬 Prompt: $prompt');

      // Validate inputs
      if (!imageFile.existsSync()) {
        print('❌ Image file does not exist!');
        throw ApiException('Image file does not exist');
      }

      if (subject.trim().isEmpty) {
        print('❌ Subject is empty!');
        throw ApiException('Subject cannot be empty');
      }

      if (prompt.trim().isEmpty) {
        print('❌ Prompt is empty!');
        throw ApiException('Prompt cannot be empty');
      }

      print('✅ Validation passed, making API request...');

      // Prepare request fields
      final fields = {'subject': subject.trim(), 'prompt': prompt.trim()};

      // Make multipart API request
      final response = await BaseApiService.postMultipart(
        '/api/direct-upload',
        file: imageFile,
        fileFieldName: 'image',
        fields: fields,
      );

      print('🎉 API request completed');

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);
      final result = ApiImageEditResponse.fromJson(jsonData);

      print(
        '✅ Direct upload successful! Processing time: ${result.processingTime}s',
      );

      return result;
    });
  }

  /// Direct upload with voice: Upload any drawing with a voice prompt
  /// For kids who want to speak what they want done with their drawing
  ///
  /// [imageFile] - The drawing image file
  /// [subject] - What the child drew (e.g., "train", "dog", "flower")
  /// [audioBytes] - Raw audio data with the voice prompt
  /// [language] - Language code: 'en' for English or 'de' for German
  ///
  /// Returns [ApiImageEditResponse] with the edited image URLs
  /// Throws [ApiException] on error
  static Future<ApiImageEditResponse> directUploadWithVoice({
    required File imageFile,
    required String subject,
    required Uint8List audioBytes,
    required String language,
  }) async {
    return await BaseApiService.handleApiCall<ApiImageEditResponse>(() async {
      print('🎨 Starting direct upload with voice request');
      print('📁 Image file: ${imageFile.path}');
      print('🏷️ Subject: $subject');
      print('🎤 Audio data: ${audioBytes.length} bytes');
      print('💬 Language: $language');

      // Validate inputs
      if (!imageFile.existsSync()) {
        print('❌ Image file does not exist!');
        throw ApiException('Image file does not exist');
      }

      if (subject.trim().isEmpty) {
        print('❌ Subject is empty!');
        throw ApiException('Subject cannot be empty');
      }

      if (audioBytes.isEmpty) {
        print('❌ Audio data is empty!');
        throw ApiException('Audio data cannot be empty');
      }

      if (language != 'en' && language != 'de') {
        print('❌ Invalid language code: $language');
        throw ApiException('Language must be "en" or "de"');
      }

      print('✅ Validation passed, making API request...');

      // Prepare request fields
      final fields = {'subject': subject.trim(), 'language': language};

      // Make multipart API request with audio
      final response = await BaseApiService.postMultipartWithAudio(
        '/api/direct-upload-audio',
        imageFile: imageFile,
        imageFieldName: 'image',
        audioBytes: audioBytes,
        audioFieldName: 'audio',
        audioFormat: 'aac',
        fields: fields,
      );

      print('🎉 API request completed');

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);
      final result = ApiImageEditResponse.fromJson(jsonData);

      print(
        '✅ Direct upload with voice successful! Processing time: ${result.processingTime}s',
      );

      return result;
    });
  }

  /// Delete a drawing from the gallery
  /// Only the owner of the drawing can delete it
  ///
  /// [drawingId] - UUID of the drawing to delete
  ///
  /// Returns true if deletion was successful
  /// Throws [ApiException] on error
  static Future<bool> deleteDrawing(String drawingId) async {
    return await BaseApiService.handleApiCall<bool>(() async {
      print('🗑️  Deleting drawing: $drawingId');

      // Validate input
      if (drawingId.trim().isEmpty) {
        print('❌ Drawing ID cannot be empty!');
        throw ApiException('Drawing ID cannot be empty');
      }

      print('✅ Validation passed, making API request...');

      // Make DELETE request
      final response = await BaseApiService.delete('/api/drawings/$drawingId');

      print('🎉 API request completed');

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);

      print('✅ Drawing deleted successfully!');

      return jsonData['success'] == true;
    });
  }

  /// Fetch a specific story for a drawing and image URL
  ///
  /// [drawingId] - UUID of the drawing
  /// [imageUrl] - URL of the image
  ///
  /// Returns story details if found, or null if not found
  /// Throws [ApiException] on error with specific error translation keys
  static Future<Map<String, dynamic>?> fetchStoryForImage(
    String drawingId,
    String imageUrl,
  ) async {
    return await BaseApiService.handleApiCall<Map<String, dynamic>?>(() async {
      // Validate input
      if (drawingId.trim().isEmpty) {
        throw ApiException('story.error_drawing_not_found');
      }

      if (imageUrl.trim().isEmpty) {
        throw ApiException('story.error_invalid_url');
      }

      // Encode image URL for use in query parameter
      final encodedUrl = Uri.encodeComponent(imageUrl);

      // Make API request with image_url as query parameter
      final response = await BaseApiService.get(
        '/api/drawings/$drawingId/stories?image_url=$encodedUrl',
      );

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);
      final story = jsonData['story'];

      if (story == null) {
        return null;
      }

      return {
        'id': story['id'] ?? '',
        'title_en': story['title_en'] ?? '',
        'title_de': story['title_de'] ?? '',
        'story_text_en': story['story_text_en'] ?? '',
        'story_text_de': story['story_text_de'] ?? '',
        'image_url': story['image_url'] ?? '',
        'is_favorite': story['is_favorite'] ?? false,
        'generation_time_ms': story['generation_time_ms'] ?? 0,
        'created_at': story['created_at'],
      };
    }).catchError((error) {
      if (error is ApiException) {
        // Check status code and error message to map to correct translation key
        if (error.statusCode == 403) {
          throw ApiException('story.error_permission_denied');
        } else if (error.statusCode == 404) {
          if (error.message.contains('Drawing not found')) {
            throw ApiException('story.error_drawing_not_found');
          } else if (error.message.contains('permission')) {
            throw ApiException('story.error_permission_denied');
          } else {
            throw ApiException('story.error_story_not_found');
          }
        } else if (error.statusCode == 500) {
          throw ApiException('story.error_server');
        }
      }
      // For any other error, throw generic error
      throw ApiException('story.error_unknown');
    });
  }
}
