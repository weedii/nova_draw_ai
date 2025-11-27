import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_exceptions.dart';

/// Base class for all API services providing common functionality
abstract class BaseApiService {
  /// Timeout duration for API requests
  static const Duration _timeout = Duration(seconds: 120);

  /// Authentication token for API requests
  static String? _authToken;

  /// Get the base URL for API requests from .env file
  static String get baseUrl {
    // final url = dotenv.env['API_BASE_URL'];
    final url = "https://novadraw-o47gf.ondigitalocean.app";
    if (url == null || url.isEmpty) {
      throw ApiException(
        'API_BASE_URL not configured in .env file',
        errorCode: 'CONFIG_ERROR',
      );
    }
    return url;
  }

  /// Get the timeout duration for API requests
  static Duration get timeout => _timeout;

  /// Set authentication token for API requests
  static void setAuthToken(String token) {
    _authToken = token;
    print('🔑 Auth token set in BaseApiService');
  }

  /// Clear authentication token
  static void clearAuthToken() {
    _authToken = null;
    print('🔓 Auth token cleared from BaseApiService');
  }

  /// Get the current authentication token (for internal use)
  static String? getAuthToken() => _authToken;

  /// Get default headers with optional auth token
  static Map<String, String> _getHeaders({
    Map<String, String>? additionalHeaders,
  }) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add auth token if available
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    // Add any additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Make a GET request to the specified endpoint
  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = _getHeaders(additionalHeaders: headers);

    return await http
        .get(url, headers: requestHeaders)
        .timeout(timeout ?? _timeout);
  }

  /// Make a POST request to the specified endpoint
  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = _getHeaders(additionalHeaders: headers);
    final requestBody = body != null ? jsonEncode(body) : null;

    return await http
        .post(url, headers: requestHeaders, body: requestBody)
        .timeout(timeout ?? _timeout);
  }

  /// Make a PUT request to the specified endpoint
  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = _getHeaders(additionalHeaders: headers);
    final requestBody = body != null ? jsonEncode(body) : null;

    return await http
        .put(url, headers: requestHeaders, body: requestBody)
        .timeout(timeout ?? _timeout);
  }

  /// Make a DELETE request to the specified endpoint
  static Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = _getHeaders(additionalHeaders: headers);

    return await http
        .delete(url, headers: requestHeaders)
        .timeout(timeout ?? _timeout);
  }

  /// Make a multipart POST request with optional file upload
  /// Can be used for file upload, form fields only, or both
  static Future<http.Response> postMultipart(
    String endpoint, {
    File? file,
    String? fileFieldName,
    Map<String, String>? fields,
    Duration? timeout,
  }) async {
    // Validate that either file or fields is provided
    if (file == null && (fields == null || fields.isEmpty)) {
      throw ArgumentError('Either file or fields must be provided');
    }

    // If file is provided, fileFieldName is required
    if (file != null && fileFieldName == null) {
      throw ArgumentError('fileFieldName is required when file is provided');
    }

    final url = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', url);

    // Add auth token if available
    if (_authToken != null) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }

    // Add file if provided
    if (file != null && fileFieldName != null) {
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
    }

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

  /// Make a multipart POST request with file upload (legacy method)
  static Future<http.Response> postMultipartWithFile(
    String endpoint, {
    required File file,
    required String fileFieldName,
    Map<String, String>? fields,
    Duration? timeout,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', url);

    // Add auth token if available
    if (_authToken != null) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }

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

  /// Make a multipart POST request with file and audio bytes
  /// This method is specifically designed for sending both an image file and audio data
  /// without saving the audio to disk
  ///
  /// [endpoint] - API endpoint path
  /// [imageFile] - The image file to upload
  /// [imageFieldName] - Form field name for the image (default: 'file')
  /// [audioBytes] - Raw audio data (e.g., AAC bytes from recording)
  /// [audioFieldName] - Form field name for the audio (default: 'audio')
  /// [audioFormat] - Audio format identifier (e.g., 'aac', 'mp4', 'wav')
  /// [fields] - Additional form fields to send
  /// [timeout] - Request timeout duration
  static Future<http.Response> postMultipartWithAudio(
    String endpoint, {
    required File imageFile,
    required String imageFieldName,
    required Uint8List audioBytes,
    required String audioFieldName,
    required String audioFormat,
    Map<String, String>? fields,
    Duration? timeout,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', url);

    // Add auth token if available
    if (_authToken != null) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }

    // Determine image content type from file extension
    String imageContentType;
    final imageExtension = imageFile.path.toLowerCase().split('.').last;
    switch (imageExtension) {
      case 'jpg':
      case 'jpeg':
        imageContentType = 'image/jpeg';
        break;
      case 'png':
        imageContentType = 'image/png';
        break;
      case 'gif':
        imageContentType = 'image/gif';
        break;
      case 'webp':
        imageContentType = 'image/webp';
        break;
      default:
        imageContentType = 'image/jpeg';
    }

    print('📤 Uploading image and audio...');
    print('🖼️  Image file: ${imageFile.path}');
    print('📝 Image Content-Type: $imageContentType');
    print('📊 Image size: ${imageFile.lengthSync()} bytes');

    // Add image file with explicit content type
    final imageMultipartFile = await http.MultipartFile.fromPath(
      imageFieldName,
      imageFile.path,
      contentType: MediaType.parse(imageContentType),
    );
    request.files.add(imageMultipartFile);
    print('✅ Image added to request');

    // Add audio bytes directly without saving to disk
    // Determine audio MIME type based on format
    String audioMimeType;
    switch (audioFormat.toLowerCase()) {
      case 'aac':
        audioMimeType = 'audio/aac';
        break;
      case 'mp4':
        audioMimeType = 'audio/mp4';
        break;
      case 'wav':
        audioMimeType = 'audio/wav';
        break;
      case 'ogg':
      case 'opus':
        audioMimeType = 'audio/ogg';
        break;
      default:
        audioMimeType = 'audio/aac'; // Default to AAC
    }

    // Create multipart file from bytes (no disk I/O needed)
    final audioMultipartFile = http.MultipartFile(
      audioFieldName,
      Stream.value(audioBytes),
      audioBytes.length,
      filename: 'audio.$audioFormat',
      contentType: MediaType.parse(audioMimeType),
    );
    request.files.add(audioMultipartFile);
    print(
      '🎤 Audio added to request (${audioBytes.length} bytes, format: $audioFormat)',
    );

    // Add additional fields
    if (fields != null) {
      request.fields.addAll(fields);
      print('📋 Additional fields: $fields');
    }

    print('🚀 Sending multipart request to: $url');

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
        throw ApiException(errorMessage, statusCode: response.statusCode);
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(
          response.reasonPhrase ?? 'Unknown error',
          statusCode: response.statusCode,
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
