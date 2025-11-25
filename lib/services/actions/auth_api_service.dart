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

  /// Request password reset (forgot password)
  ///
  /// [email] - User's email address
  ///
  /// Returns [MessageResponse] with confirmation message
  /// Throws [ApiException] on error
  static Future<MessageResponse> forgotPassword({required String email}) async {
    return await BaseApiService.handleApiCall<MessageResponse>(() async {
      if (email.trim().isEmpty) {
        throw ApiException('Email cannot be empty');
      }

      print('🔑 Requesting password reset for: $email');

      final response = await BaseApiService.post(
        '/auth/forgot-password',
        body: {'email': email.trim()},
      );

      final jsonData = BaseApiService.handleResponse(response);
      print('✅ Password reset email sent');
      return MessageResponse.fromJson(jsonData);
    });
  }

  /// Reset password with OTP code
  ///
  /// [email] - User's email address
  /// [code] - 6-digit OTP code from email
  /// [newPassword] - New password (min 6 characters)
  ///
  /// Returns [MessageResponse] with confirmation message
  /// Throws [ApiException] on error
  static Future<MessageResponse> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    return await BaseApiService.handleApiCall<MessageResponse>(() async {
      if (email.trim().isEmpty) {
        throw ApiException('Email cannot be empty');
      }
      if (code.trim().isEmpty || code.trim().length != 6) {
        throw ApiException('Please enter a valid 6-digit code');
      }
      if (newPassword.length < 6) {
        throw ApiException('Password must be at least 6 characters');
      }

      print('🔐 Resetting password for: $email');

      final response = await BaseApiService.post(
        '/auth/reset-password',
        body: {
          'email': email.trim(),
          'code': code.trim(),
          'new_password': newPassword,
        },
      );

      final jsonData = BaseApiService.handleResponse(response);
      print('✅ Password reset successful');
      return MessageResponse.fromJson(jsonData);
    });
  }

  /// Change password for authenticated user
  ///
  /// [currentPassword] - Current password for verification
  /// [newPassword] - New password (min 6 characters)
  ///
  /// Returns [MessageResponse] with confirmation message
  /// Throws [ApiException] on error
  static Future<MessageResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await BaseApiService.handleApiCall<MessageResponse>(() async {
      if (currentPassword.isEmpty) {
        throw ApiException('Current password cannot be empty');
      }
      if (newPassword.length < 6) {
        throw ApiException('New password must be at least 6 characters');
      }

      print('🔄 Changing password...');

      final response = await BaseApiService.post(
        '/auth/change-password',
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      final jsonData = BaseApiService.handleResponse(response);
      print('✅ Password changed successfully');
      return MessageResponse.fromJson(jsonData);
    });
  }
}
