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
  /// Throws [ApiException] on error
  static Future<List<ApiEditOption>> getEditOptions({
    required String category,
    required String subject,
  }) async {
    return await BaseApiService.handleApiCall<List<ApiEditOption>>(() async {
      print('📋 Fetching edit options for $category/$subject');

      // Validate inputs
      if (category.trim().isEmpty) {
        throw ApiException('Category cannot be empty');
      }

      if (subject.trim().isEmpty) {
        throw ApiException('Subject cannot be empty');
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
    });
  }

  /// Fetch all categories with edit options
  ///
  /// Returns list of category names
  /// Throws [ApiException] on error
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
    });
  }

  /// Fetch all subjects in a specific category
  ///
  /// [category] - The category name
  ///
  /// Returns list of subject names
  /// Throws [ApiException] on error
  static Future<List<String>> getSubjectsByCategory(String category) async {
    return await BaseApiService.handleApiCall<List<String>>(() async {
      print('📂 Fetching subjects for category: $category');

      // Validate input
      if (category.trim().isEmpty) {
        throw ApiException('Category cannot be empty');
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
    });
  }
}
