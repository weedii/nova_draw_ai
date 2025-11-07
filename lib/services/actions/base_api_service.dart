import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exceptions.dart';

/// Base class for all API services providing common functionality
abstract class BaseApiService {
  /// Base URL for the backend API
  static const String _baseUrl = 'http://192.168.0.26:8000';
  
  /// Timeout duration for API requests
  static const Duration _timeout = Duration(seconds: 180);

  /// Get the base URL for API requests
  static String get baseUrl => _baseUrl;

  /// Get the timeout duration for API requests
  static Duration get timeout => _timeout;

  /// Make a GET request to the specified endpoint
  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    return await http
        .get(url, headers: defaultHeaders)
        .timeout(timeout ?? _timeout);
  }

  /// Make a POST request to the specified endpoint
  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    final requestBody = body != null ? jsonEncode(body) : null;

    return await http
        .post(url, headers: defaultHeaders, body: requestBody)
        .timeout(timeout ?? _timeout);
  }

  /// Make a PUT request to the specified endpoint
  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    final requestBody = body != null ? jsonEncode(body) : null;

    return await http
        .put(url, headers: defaultHeaders, body: requestBody)
        .timeout(timeout ?? _timeout);
  }

  /// Make a DELETE request to the specified endpoint
  static Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    return await http
        .delete(url, headers: defaultHeaders)
        .timeout(timeout ?? _timeout);
  }

  /// Handle API response and parse JSON
  static Map<String, dynamic> handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      // Try to parse error response
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['detail'] ?? 'Unknown error occurred';
        throw ApiException(
          'API Error (${response.statusCode}): $errorMessage',
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(
          'HTTP Error (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    }
  }

  /// Handle common API exceptions
  static Future<T> handleApiCall<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
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


/// API configuration class for easy customization
class ApiConfig {
  static String _baseUrl = 'http://192.168.0.26:8000';
  static Duration _timeout = const Duration(seconds: 180);

  /// Get the current base URL
  static String get baseUrl => _baseUrl;

  /// Get the current timeout duration
  static Duration get timeout => _timeout;

  /// Update the base URL (useful for different environments)
  static void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Update the timeout duration
  static void setTimeout(Duration duration) {
    _timeout = duration;
  }
}
