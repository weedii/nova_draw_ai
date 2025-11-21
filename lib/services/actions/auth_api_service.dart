import '../../models/user_model.dart';
import 'base_api_service.dart';
import 'api_exceptions.dart';

/// API service for authentication operations
/// Follows the same pattern as DrawingApiService
class AuthApiService {
  /// Register a new user
  ///
  /// [email] - User's email address
  /// [password] - User's password (min 6 characters)
  /// [name] - User's name (optional)
  /// [birthdate] - User's birthdate (optional)
  ///
  /// Returns [AuthResponse] with tokens and user info
  /// Throws [ApiException] on error
  static Future<AuthResponse> register({
    required String email,
    required String password,
    String? name,
    DateTime? birthdate,
  }) async {
    return await BaseApiService.handleApiCall<AuthResponse>(() async {
      // Validate input
      if (email.trim().isEmpty) {
        throw ApiException('Email cannot be empty');
      }

      if (password.isEmpty) {
        throw ApiException('Password cannot be empty');
      }

      if (password.length < 6) {
        throw ApiException('Password must be at least 6 characters');
      }

      // Prepare request body
      final body = {
        'email': email.trim(),
        'password': password,
        if (name != null && name.isNotEmpty) 'name': name.trim(),
        if (birthdate != null)
          'birthdate': birthdate.toIso8601String().split('T')[0],
      };

      print('🚀 Registering user: $email');

      // Make API request
      final response = await BaseApiService.post(
        '/auth/register',
        body: body,
      );

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);
      final authResponse = AuthResponse.fromJson(jsonData);

      print('✅ Registration successful!');
      return authResponse;
    });
  }

  /// Login existing user
  ///
  /// [email] - User's email address
  /// [password] - User's password
  ///
  /// Returns [AuthResponse] with tokens and user info
  /// Throws [ApiException] on error
  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await BaseApiService.handleApiCall<AuthResponse>(() async {
      // Validate input
      if (email.trim().isEmpty) {
        throw ApiException('Email cannot be empty');
      }

      if (password.isEmpty) {
        throw ApiException('Password cannot be empty');
      }

      // Prepare request body
      final body = {
        'email': email.trim(),
        'password': password,
      };

      print('🚀 Logging in user: $email');

      // Make API request
      final response = await BaseApiService.post(
        '/auth/login',
        body: body,
      );

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);
      final authResponse = AuthResponse.fromJson(jsonData);

      print('✅ Login successful!');
      return authResponse;
    });
  }

  /// Get current user profile
  ///
  /// Requires valid access token to be set in BaseApiService
  /// Returns [User] profile data
  /// Throws [ApiException] on error
  static Future<User> getCurrentUser() async {
    return await BaseApiService.handleApiCall<User>(() async {
      print('🚀 Getting current user');

      // Make API request (token will be auto-injected by BaseApiService)
      final response = await BaseApiService.get('/auth/me');

      // Handle response
      final jsonData = BaseApiService.handleResponse(response);
      final user = User.fromJson(jsonData);

      print('✅ Got current user: ${user.email}');
      return user;
    });
  }

  // Note: Token refresh endpoint removed because tokens never expire
  // Backend tokens are configured to never expire for kid-friendly UX

  /// Test connection to backend
  ///
  /// Returns true if backend is reachable
  /// Throws [ApiException] on error
  static Future<bool> testConnection() async {
    return await BaseApiService.handleApiCall<bool>(() async {
      print('🧪 Testing connection to backend');

      final response = await BaseApiService.get('/health');

      print('✅ Backend connection successful');
      return response.statusCode == 200;
    });
  }
}
