import '../../models/api_models.dart';
import 'base_api_service.dart';
import 'api_exceptions.dart';

/// API service for fetching edit options from the backend
class EditOptionApiService {
  /// Fetch all edit options for a specific subject
  ///
  /// [category] - The category name (e.g., 'Animals')
  /// [subject] - The subject name (e.g., 'dog')
  ///
  /// Returns list of [ApiEditOption] objects
  /// Throws [ApiException] on error with specific error translation keys
  static Future<List<ApiEditOption>> getEditOptions({
    required String category,
    required String subject,
  }) async {
    return await BaseApiService.handleApiCall<List<ApiEditOption>>(() async {
      print('📋 Fetching edit options for $category/$subject');

      // Validate inputs
      if (category.trim().isEmpty) {
        throw ApiException('edit_options.error_category_not_found');
      }

      if (subject.trim().isEmpty) {
        throw ApiException('edit_options.error_no_options');
      }

      // Make API request
      final response = await BaseApiService.get(
        '/api/edit-options/${Uri.encodeComponent(category)}/${Uri.encodeComponent(subject)}',
      );

      print('✅ API response received');

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);

      // Parse the response - it should have a 'data' field with list of edit options
      final dataList = jsonData['data'] as List<dynamic>? ?? [];

      print('📊 Found ${dataList.length} edit options');

      return dataList
          .map((item) => ApiEditOption.fromJson(item as Map<String, dynamic>))
          .toList();
    }).catchError((error) {
      if (error is ApiException) {
        // Check status code and error message to map to correct translation key
        if (error.statusCode == 404) {
          if (error.message.contains('No edit options')) {
            throw ApiException('edit_options.error_no_options');
          } else if (error.message.contains('not found')) {
            throw ApiException('edit_options.error_category_not_found');
          }
        } else if (error.statusCode == 500) {
          throw ApiException('edit_options.error_server');
        }
      }
      // For any other error, throw generic error
      throw ApiException('edit_options.error_unknown');
    });
  }

  /// Fetch all categories with edit options
  ///
  /// Returns list of category names
  /// Throws [ApiException] on error with specific error translation keys
  static Future<List<String>> getCategories() async {
    return await BaseApiService.handleApiCall<List<String>>(() async {
      print('📂 Fetching all categories');

      final response = await BaseApiService.get('/api/edit-options/categories');

      print('✅ Categories response received');

      final jsonData = BaseApiService.handleResponse(response);

      // Parse the response - it should have a 'data' field with list of categories
      final dataList = jsonData['data'] as List<dynamic>? ?? [];

      print('📊 Found ${dataList.length} categories');

      return dataList.map((item) => item.toString()).toList();
    }).catchError((error) {
      if (error is ApiException) {
        // Check status code and error message to map to correct translation key
        if (error.statusCode == 404) {
          throw ApiException('edit_options.error_no_categories');
        } else if (error.statusCode == 500) {
          throw ApiException('edit_options.error_server');
        }
      }
      // For any other error, throw generic error
      throw ApiException('edit_options.error_unknown');
    });
  }

  /// Fetch all subjects in a specific category
  ///
  /// [category] - The category name
  ///
  /// Returns list of subject names
  /// Throws [ApiException] on error with specific error translation keys
  static Future<List<String>> getSubjectsByCategory(String category) async {
    return await BaseApiService.handleApiCall<List<String>>(() async {
      print('📂 Fetching subjects for category: $category');

      // Validate input
      if (category.trim().isEmpty) {
        throw ApiException('edit_options.error_category_not_found');
      }

      final response = await BaseApiService.get(
        '/api/edit-options/categories/${Uri.encodeComponent(category)}/subjects',
      );

      print('✅ Subjects response received');

      final jsonData = BaseApiService.handleResponse(response);

      // Parse the response - it should have a 'data' field with list of subjects
      final dataList = jsonData['data'] as List<dynamic>? ?? [];

      print('📊 Found ${dataList.length} subjects');

      return dataList.map((item) => item.toString()).toList();
    }).catchError((error) {
      if (error is ApiException) {
        // Check status code and error message to map to correct translation key
        if (error.statusCode == 404) {
          if (error.message.contains('not found')) {
            throw ApiException('edit_options.error_category_not_found');
          } else if (error.message.contains('No subjects')) {
            throw ApiException('edit_options.error_no_subjects');
          }
        } else if (error.statusCode == 500) {
          throw ApiException('edit_options.error_server');
        }
      }
      // For any other error, throw generic error
      throw ApiException('edit_options.error_unknown');
    });
  }
}
