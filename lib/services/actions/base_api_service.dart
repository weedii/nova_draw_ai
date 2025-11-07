import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

  /// Make a multipart POST request with file upload
  static Future<http.Response> postMultipart(
    String endpoint, {
    required File file,
    required String fileFieldName,
    Map<String, String>? fields,
    Duration? timeout,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final request = http.MultipartRequest('POST', url);

    // Determine content type from file extension
    String? contentType;
    final extension = file.path.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        contentType = 'image/jpeg';
        break;
      case 'png':
        contentType = 'image/png';
        break;
      case 'gif':
        contentType = 'image/gif';
        break;
      case 'webp':
        contentType = 'image/webp';
        break;
      default:
        contentType = 'image/jpeg'; // Default fallback
    }

    print('📤 Uploading file: ${file.path}');
    print('📝 Content-Type: $contentType');
    print('📊 File size: ${file.lengthSync()} bytes');

    // Add file with explicit content type
    final multipartFile = await http.MultipartFile.fromPath(
      fileFieldName,
      file.path,
      contentType: MediaType.parse(contentType),
    );

    request.files.add(multipartFile);
    print('✅ File added to request: ${multipartFile.filename}');

    // Add additional fields
    if (fields != null) {
      request.fields.addAll(fields);
      print('📋 Fields: $fields');
    }

    print('🚀 Sending request to: $url');

    // Send request
    final streamedResponse = await request.send().timeout(timeout ?? _timeout);

    print('📥 Response status: ${streamedResponse.statusCode}');

    // Convert streamed response to regular response
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 400) {
      print('❌ Error response: ${response.body}');
    } else {
      print('✅ Success response received');
    }

    return response;
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
        throw ApiException('API Error (${response.statusCode}): $errorMessage');
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
