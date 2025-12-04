/// Custom exception for API-related errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const ApiException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => 'ApiException: $message';

  /// Create an ApiException from HTTP response
  factory ApiException.fromResponse(
    int statusCode,
    String? reasonPhrase, [
    String? detail,
  ]) {
    return ApiException(
      detail ?? 'HTTP Error ($statusCode): $reasonPhrase',
      statusCode: statusCode,
    );
  }

  /// Create an ApiException for network errors
  factory ApiException.network(String message) {
    return ApiException('Network error: $message', errorCode: 'NETWORK_ERROR');
  }

  /// Create an ApiException for timeout errors
  factory ApiException.timeout() {
    return ApiException('Request timeout', errorCode: 'TIMEOUT');
  }

  /// Create an ApiException for validation errors
  factory ApiException.validation(String message) {
    return ApiException(
      'Validation error: $message',
      errorCode: 'VALIDATION_ERROR',
    );
  }

  /// Create an ApiException for parsing errors
  factory ApiException.parsing(String message) {
    return ApiException(
      'Invalid response format: $message',
      errorCode: 'PARSING_ERROR',
    );
  }
}

/// Base class for API response models
abstract class ApiResponseModel {
  /// Convert the model to JSON
  Map<String, dynamic> toJson();

  /// Create the model from JSON
  static T fromJson<T extends ApiResponseModel>(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson must be implemented by subclasses');
  }
}

/// Standard API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? errorCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errorCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? dataFromJson,
  ) {
    return ApiResponse<T>(
      success: json['success'] == true || json['success'] == 'true',
      data: json['data'] != null && dataFromJson != null
          ? dataFromJson(json['data'])
          : null,
      message: json['message'],
      errorCode: json['error_code'],
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T)? dataToJson) {
    return {
      'success': success,
      'data': data != null && dataToJson != null ? dataToJson(data as T) : data,
      'message': message,
      'error_code': errorCode,
    };
  }
}
