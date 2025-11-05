import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_models.dart';

class ApiService {
  // Base URL for the backend API
  // Use 10.0.2.2 for Android Emulator (maps to host machine's localhost)
  // Use your computer's IP address for physical devices
  static const String _baseUrl = 'http://192.168.0.26:8000';

  // Timeout duration for API requests
  static const Duration _timeout = Duration(seconds: 180);

  /// Generate a complete drawing tutorial from the backend API
  ///
  /// [subject] - What to draw (e.g., "cat", "dog", "butterfly")
  ///
  /// Returns [ApiDrawingStepResponse] with all steps and base64 images
  /// Throws [ApiException] on error
  static Future<ApiDrawingStepResponse> generateTutorial(String subject) async {
    try {
      // Validate input
      if (subject.trim().isEmpty) {
        throw ApiException('Subject cannot be empty');
      }

      if (subject.length > 100) {
        throw ApiException('Subject name too long (max 100 characters)');
      }

      // Prepare request
      final url = Uri.parse('$_baseUrl/api/generate-tutorial');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      final body = jsonEncode({'subject': subject.trim()});

      // Make API request
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(_timeout);

      // Handle response
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return ApiDrawingStepResponse.fromJson(jsonData);
      } else {
        // Try to parse error response
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['detail'] ?? 'Unknown error occurred';
          throw ApiException(
            'API Error (${response.statusCode}): $errorMessage',
          );
        } catch (e) {
          throw ApiException(
            'HTTP Error (${response.statusCode}): ${response.reasonPhrase}',
          );
        }
      }
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw ApiException('Invalid response format: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: ${e.toString()}');
    }
  }
}

/// Custom exception for API-related errors
class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

/// API configuration class for easy customization
class ApiConfig {
  static String baseUrl = 'http://localhost:8000';
  static Duration timeout = const Duration(seconds: 60);

  /// Update the base URL (useful for different environments)
  static void setBaseUrl(String url) {
    baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Update the timeout duration
  static void setTimeout(Duration duration) {
    timeout = duration;
  }
}
