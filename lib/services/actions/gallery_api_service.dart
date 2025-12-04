import '../../models/api_models.dart';
import 'base_api_service.dart';
import 'api_exceptions.dart';

/// API service for gallery operations
/// Handles fetching user's drawings and gallery-related operations
class GalleryApiService {
  /// Fetch user's gallery with pagination
  ///
  /// [page] - Page number (1-indexed, default: 1)
  /// [limit] - Items per page (default: 20, max: 100)
  ///
  /// Returns [ApiGalleryListResponse] with paginated drawings
  /// Throws [ApiException] on error with specific error translation keys
  static Future<ApiGalleryListResponse> fetchGallery({
    int page = 1,
    int limit = 50,
  }) async {
    return await BaseApiService.handleApiCall<ApiGalleryListResponse>(() async {
      // Validate pagination parameters
      if (page < 1) {
        throw ApiException('gallery.error_invalid_pagination');
      }

      if (limit < 1 || limit > 100) {
        throw ApiException('gallery.error_invalid_pagination');
      }

      // Make API request
      final response = await BaseApiService.get(
        '/api/drawings/gallery?page=$page&limit=$limit',
      );

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);
      return ApiGalleryListResponse.fromJson(jsonData);
    }).catchError((error) {
      if (error is ApiException) {
        // Check status code and error message to map to correct translation key
        if (error.statusCode == 400) {
          throw ApiException('gallery.error_invalid_pagination');
        } else if (error.statusCode == 500) {
          throw ApiException('gallery.error_server');
        }
      }
      // For any other error, throw generic error
      throw ApiException('gallery.error_unknown');
    });
  }

  /// Fetch a single drawing by ID
  ///
  /// [drawingId] - UUID of the drawing
  ///
  /// Returns [ApiGalleryDrawing] with drawing details
  /// Throws [ApiException] on error with specific error translation keys
  static Future<ApiGalleryDrawing> fetchDrawing(String drawingId) async {
    return await BaseApiService.handleApiCall<ApiGalleryDrawing>(() async {
      // Validate input
      if (drawingId.trim().isEmpty) {
        throw ApiException('gallery.error_drawing_not_found');
      }

      // Make API request
      final response = await BaseApiService.get('/api/drawings/$drawingId');

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);
      return ApiGalleryDrawing.fromJson(jsonData);
    }).catchError((error) {
      if (error is ApiException) {
        // Check status code and error message to map to correct translation key
        if (error.statusCode == 403) {
          throw ApiException('gallery.error_permission_denied');
        } else if (error.statusCode == 404) {
          throw ApiException('gallery.error_drawing_not_found');
        } else if (error.statusCode == 500) {
          throw ApiException('gallery.error_server');
        }
      }
      // For any other error, throw generic error
      throw ApiException('gallery.error_unknown');
    });
  }

  /// Delete a drawing from gallery
  ///
  /// [drawingId] - UUID of the drawing to delete
  ///
  /// Returns success status
  /// Throws [ApiException] on error with specific error translation keys
  static Future<bool> deleteDrawing(String drawingId) async {
    return await BaseApiService.handleApiCall<bool>(() async {
      // Validate input
      if (drawingId.trim().isEmpty) {
        throw ApiException('gallery.error_drawing_not_found');
      }

      // Make API request
      final response = await BaseApiService.delete('/api/drawings/$drawingId');

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);
      return jsonData['success'] == true || jsonData['success'] == 'true';
    }).catchError((error) {
      if (error is ApiException) {
        // Check status code and error message to map to correct translation key
        if (error.statusCode == 403) {
          throw ApiException('gallery.error_permission_denied');
        } else if (error.statusCode == 404) {
          throw ApiException('gallery.error_drawing_not_found');
        } else if (error.statusCode == 500) {
          throw ApiException('gallery.error_server');
        }
      }
      // For any other error, throw generic error
      throw ApiException('gallery.error_delete_failed');
    });
  }

  /// Delete a specific image from a drawing by URL
  ///
  /// [drawingId] - UUID of the drawing
  /// [imageUrl] - URL of the image to delete
  ///
  /// Returns success status
  /// Throws [ApiException] on error with specific error translation keys
  static Future<bool> deleteDrawingImage(
    String drawingId,
    String imageUrl,
  ) async {
    return await BaseApiService.handleApiCall<bool>(() async {
      // Validate input
      if (drawingId.trim().isEmpty) {
        throw ApiException('gallery.error_drawing_not_found');
      }

      if (imageUrl.trim().isEmpty) {
        throw ApiException('gallery.error_image_not_found');
      }

      // Make API request with image_url as query parameter
      final encodedUrl = Uri.encodeComponent(imageUrl);
      final response = await BaseApiService.delete(
        '/api/drawings/$drawingId/images?image_url=$encodedUrl',
      );

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);
      return jsonData['success'] == true || jsonData['success'] == 'true';
    }).catchError((error) {
      if (error is ApiException) {
        // Check status code and error message to map to correct translation key
        if (error.statusCode == 403) {
          throw ApiException('gallery.error_permission_denied');
        } else if (error.statusCode == 404) {
          if (error.message.contains('Drawing not found')) {
            throw ApiException('gallery.error_drawing_not_found');
          } else if (error.message.contains('Image not found')) {
            throw ApiException('gallery.error_image_not_found');
          }
        } else if (error.statusCode == 500) {
          throw ApiException('gallery.error_server');
        }
      }
      // For any other error, throw generic error
      throw ApiException('gallery.error_delete_image_failed');
    });
  }

  /// Fetch gallery statistics
  ///
  /// Returns map with stats: total_drawings, edited_drawings, tutorial_drawings
  /// Throws [ApiException] on error with specific error translation keys
  static Future<Map<String, int>> fetchGalleryStats() async {
    return await BaseApiService.handleApiCall<Map<String, int>>(() async {
      // Make API request
      final response = await BaseApiService.get('/api/drawings/stats/summary');

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);
      return {
        'total_drawings': jsonData['total_drawings'] ?? 0,
        'edited_drawings': jsonData['edited_drawings'] ?? 0,
        'tutorial_drawings': jsonData['tutorial_drawings'] ?? 0,
      };
    }).catchError((error) {
      if (error is ApiException) {
        // Check status code to map to correct translation key
        if (error.statusCode == 500) {
          throw ApiException('gallery.error_server');
        }
      }
      // For any other error, throw generic error
      throw ApiException('gallery.error_stats_failed');
    });
  }
}
