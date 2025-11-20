import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Authentication service for handling user registration, login, and token management
class AuthService {
  // Get API base URL from environment
  static String get baseUrl {
    // TEMPORARY: Hardcoded for testing
    // TODO: Fix .env loading issue
    const url = 'http://10.0.2.2:8000';  // Android emulator
    // const url = 'http://196.178.132.202:8000';  // Physical device
    
    print('🌐 API Base URL (hardcoded): $url');
    return url;
    
    // Original code (not working):
    // final apiUrl = dotenv.env['API_BASE_URL'] ?? 'localhost';
    // final port = dotenv.env['PORT'] ?? '8000';
    // final url = 'http://$apiUrl:$port';
    // return url;
  }

  /// Test connection to backend
  static Future<bool> testConnection() async {
    try {
      print('🧪 Testing connection to: $baseUrl/health');
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      print('📥 Health check status: ${response.statusCode}');
      print('📥 Health check body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }

  /// Register a new user
  /// 
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password (min 6 characters)
  /// - [name]: User's name (optional)
  /// - [birthdate]: User's birthdate (optional)
  /// 
  /// Returns [AuthResponse] with tokens and user info
  /// Throws [Exception] if registration fails
  static Future<AuthResponse> register({
    required String email,
    required String password,
    String? name,
    DateTime? birthdate,
  }) async {
    try {
      print('🔧 Starting registration...');
      print('📍 Base URL: $baseUrl');
      
      final url = Uri.parse('$baseUrl/auth/register');
      
      final body = {
        'email': email,
        'password': password,
        if (name != null && name.isNotEmpty) 'name': name,
        if (birthdate != null) 'birthdate': birthdate.toIso8601String().split('T')[0],
      };

      print('🚀 Registering user: $email');
      print('📍 Full URL: $url');
      print('📦 Request body: $body');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection and try again.');
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        
        // Save tokens
        await _saveTokens(
          authResponse.accessToken,
          authResponse.refreshToken,
        );
        
        print('✅ Registration successful!');
        return authResponse;
      } else {
        // Handle error response
        try {
          final error = jsonDecode(response.body);
          final errorMessage = error['detail'] ?? 'Registration failed. Please try again.';
          print('❌ Registration failed: $errorMessage');
          throw Exception(errorMessage);
        } catch (e) {
          // If it's already our Exception with the error message, rethrow it
          if (e is Exception && e.toString().contains('Exception: ')) {
            rethrow;
          }
          // Otherwise, it's a JSON parsing error
          print('❌ Failed to parse error response: $e');
          throw Exception('Registration failed. Please try again.');
        }
      }
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error. Please check your connection and try again.');
    } catch (e) {
      print('❌ Registration error: $e');
      // If it's already an Exception with our error message, rethrow it
      if (e is Exception && e.toString().contains('Exception: ')) {
        rethrow;
      }
      throw Exception('Registration failed: $e');
    }
  }

  /// Login existing user
  /// 
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password
  /// 
  /// Returns [AuthResponse] with tokens and user info
  /// Throws [Exception] if login fails
  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      
      final body = {
        'email': email,
        'password': password,
      };

      print('🚀 Logging in user: $email');
      print('📍 URL: $url');
      print('📦 Request body: $body');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection and try again.');
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        
        // Save tokens
        await _saveTokens(
          authResponse.accessToken,
          authResponse.refreshToken,
        );
        
        print('✅ Login successful!');
        return authResponse;
      } else {
        // Handle error response
        try {
          final error = jsonDecode(response.body);
          final errorMessage = error['detail'] ?? 'Login failed. Please try again.';
          print('❌ Login failed: $errorMessage');
          throw Exception(errorMessage);
        } catch (e) {
          // If it's already our Exception with the error message, rethrow it
          if (e is Exception && e.toString().contains('Exception: ')) {
            rethrow;
          }
          // Otherwise, it's a JSON parsing error
          print('❌ Failed to parse error response: $e');
          throw Exception('Login failed. Please try again.');
        }
      }
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error. Please check your connection and try again.');
    } catch (e) {
      print('❌ Login error: $e');
      // If it's already an Exception with our error message, rethrow it
      if (e is Exception && e.toString().contains('Exception: ')) {
        rethrow;
      }
      throw Exception('Login failed: $e');
    }
  }

  /// Get current user profile
  /// 
  /// Requires valid access token
  /// Returns [User] profile data
  /// Throws [Exception] if request fails
  static Future<User> getCurrentUser() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token found. Please login.');
      }

      final url = Uri.parse('$baseUrl/auth/me');
      
      print('🚀 Getting current user');
      print('📍 URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final user = User.fromJson(jsonDecode(response.body));
        print('✅ Got current user: ${user.email}');
        return user;
      } else {
        final error = jsonDecode(response.body);
        final errorMessage = error['detail'] ?? 'Failed to get user';
        print('❌ Get user failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Get user error: $e');
      rethrow;
    }
  }

  /// Refresh access token
  /// 
  /// Uses refresh token to get a new access token
  /// Returns new access token
  /// Throws [Exception] if refresh fails
  static Future<String> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token found. Please login.');
      }

      final url = Uri.parse('$baseUrl/auth/refresh');
      
      print('🚀 Refreshing access token');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refresh_token': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access_token'];
        
        // Save new access token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', newAccessToken);
        
        print('✅ Token refreshed successfully');
        return newAccessToken;
      } else {
        final error = jsonDecode(response.body);
        final errorMessage = error['detail'] ?? 'Token refresh failed';
        print('❌ Token refresh failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Token refresh error: $e');
      rethrow;
    }
  }

  /// Save tokens to local storage
  static Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    print('💾 Tokens saved to local storage');
  }

  /// Get access token from local storage
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Get refresh token from local storage
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null;
  }

  /// Logout user (clear tokens)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    print('👋 User logged out - tokens cleared');
  }
}
