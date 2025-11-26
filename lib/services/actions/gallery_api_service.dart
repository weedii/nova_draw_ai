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
  /// Throws [ApiException] on error
  static Future<ApiGalleryListResponse> fetchGallery({
    int page = 1,
    int limit = 50,
  }) async {
    return await BaseApiService.handleApiCall<ApiGalleryListResponse>(() async {
      // Validate pagination parameters
      if (page < 1) {
        throw ApiException('Page number must be at least 1');
      }

      if (limit < 1 || limit > 100) {
        throw ApiException('Limit must be between 1 and 100');
      }

      // Make API request
      final response = await BaseApiService.get(
        '/api/drawings/gallery?page=$page&limit=$limit',
      );

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);
      return ApiGalleryListResponse.fromJson(jsonData);
    });
  }

  /// Fetch a single drawing by ID
  ///
  /// [drawingId] - UUID of the drawing
  ///
  /// Returns [ApiGalleryDrawing] with drawing details
  /// Throws [ApiException] on error
  static Future<ApiGalleryDrawing> fetchDrawing(String drawingId) async {
    return await BaseApiService.handleApiCall<ApiGalleryDrawing>(() async {
      // Validate input
      if (drawingId.trim().isEmpty) {
        throw ApiException('Drawing ID cannot be empty');
      }

      // Make API request
      final response = await BaseApiService.get('/api/drawings/$drawingId');

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);
      return ApiGalleryDrawing.fromJson(jsonData);
    });
  }

  /// Delete a drawing from gallery
  ///
  /// [drawingId] - UUID of the drawing to delete
  ///
  /// Returns success status
  /// Throws [ApiException] on error
  static Future<bool> deleteDrawing(String drawingId) async {
    return await BaseApiService.handleApiCall<bool>(() async {
      // Validate input
      if (drawingId.trim().isEmpty) {
        throw ApiException('Drawing ID cannot be empty');
      }

      // Make API request
      final response = await BaseApiService.delete('/api/drawings/$drawingId');

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);
      return jsonData['success'] == true || jsonData['success'] == 'true';
    });
  }

  /// Fetch gallery statistics
  ///
  /// Returns map with stats: total_drawings, edited_drawings, tutorial_drawings
  /// Throws [ApiException] on error
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
    });
  }
}
