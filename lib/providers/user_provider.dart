import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/actions/auth_api_service.dart';
import '../services/actions/api_exceptions.dart';
import '../services/actions/base_api_service.dart';

/// Authentication state enum
enum AuthState {
  initial, // App just started, checking auth status
  loading, // Performing auth operation
  authenticated, // User is logged in
  unauthenticated, // User is not logged in
  error, // Auth operation failed
}

/// User provider for managing user state and authentication
/// Follows the same pattern as DrawingProvider
class UserProvider extends ChangeNotifier {
  // Secure storage instance
  static const _storage = FlutterSecureStorage();

  // Storage keys
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userDataKey = 'user_data';

  // State
  AuthState _state = AuthState.initial;
  User? _currentUser;
  String? _error;
  String? _accessToken;
  String? _refreshToken;

  // Getters
  AuthState get state => _state;
  User? get currentUser => _currentUser;
  String? get error => _error;
  bool get isLoading => _state == AuthState.loading;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isUnauthenticated => _state == AuthState.unauthenticated;
  String? get accessToken => _accessToken;

  /// Initialize auth state on app start
  /// Checks for stored tokens and validates them
  Future<void> checkAuthStatus() async {
    print('🔐 Checking auth status...');

    _state = AuthState.initial;
    _error = null;
    notifyListeners();

    try {
      // Try to load tokens from secure storage
      _accessToken = await _storage.read(key: _accessTokenKey);
      _refreshToken = await _storage.read(key: _refreshTokenKey);

      if (_accessToken != null && _refreshToken != null) {
        print('✅ Found stored tokens');

        // Set token in BaseApiService for API calls
        BaseApiService.setAuthToken(_accessToken!);

        // Try to load user data
        try {
          _currentUser = await AuthApiService.getCurrentUser();
          _state = AuthState.authenticated;
          _error = null;
          print('✅ User authenticated: ${_currentUser!.email}');
        } catch (e) {
          print('❌ Token validation failed: $e');
          // Token is invalid, clear everything
          await _clearAuth();
          _state = AuthState.unauthenticated;
        }
      } else {
        print('ℹ️ No stored tokens found');
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      print('❌ Error checking auth status: $e');
      _state = AuthState.unauthenticated;
      _error = e.toString();
    }

    notifyListeners();
  }

  /// Register a new user
  Future<void> register({
    required String email,
    required String password,
    String? name,
    DateTime? birthdate,
  }) async {
    print('📝 Starting registration...');

    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      // Call API
      final authResponse = await AuthApiService.register(
        email: email,
        password: password,
        name: name,
        birthdate: birthdate,
      );

      // Save tokens
      await _saveTokens(authResponse.accessToken, authResponse.refreshToken);

      // Set token in BaseApiService
      BaseApiService.setAuthToken(authResponse.accessToken);

      // Update state
      _currentUser = authResponse.user;
      _state = AuthState.authenticated;
      _error = null;

      print('✅ Registration successful: ${_currentUser!.email}');
      notifyListeners();
    } on ApiException catch (e) {
      print('❌ Registration failed: ${e.message}');
      _state = AuthState.error;
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      print('❌ Registration error: $e');
      _state = AuthState.error;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Login existing user
  Future<void> login({required String email, required String password}) async {
    print('🔑 Starting login...');

    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      // Call API
      final authResponse = await AuthApiService.login(
        email: email,
        password: password,
      );

      // Save tokens
      await _saveTokens(authResponse.accessToken, authResponse.refreshToken);

      // Set token in BaseApiService
      BaseApiService.setAuthToken(authResponse.accessToken);

      // Update state
      _currentUser = authResponse.user;
      _state = AuthState.authenticated;
      _error = null;

      print('✅ Login successful: ${_currentUser!.email}');
      notifyListeners();
    } on ApiException catch (e) {
      print('❌ Login failed: ${e.message}');
      _state = AuthState.error;
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      print('❌ Login error: $e');
      _state = AuthState.error;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    print('👋 Logging out...');

    _state = AuthState.loading;
    notifyListeners();

    try {
      // Clear all auth data
      await _clearAuth();

      _state = AuthState.unauthenticated;
      _error = null;

      print('✅ Logout successful');
      notifyListeners();
    } catch (e) {
      print('❌ Logout error: $e');
      // Even if there's an error, clear local state
      await _clearAuth();
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  // Note: Token refresh methods removed

  /// Load current user data
  Future<void> loadUser() async {
    if (_state != AuthState.authenticated) {
      print('⚠️ Cannot load user: not authenticated');
      return;
    }

    try {
      print('📥 Loading user data...');

      _currentUser = await AuthApiService.getCurrentUser();

      print('✅ User data loaded: ${_currentUser!.email}');

      notifyListeners();
    } catch (e) {
      print('❌ Failed to load user: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Save tokens to secure storage
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);

    print('💾 Tokens saved to secure storage');
  }

  /// Clear all auth data
  Future<void> _clearAuth() async {
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;

    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userDataKey);

    // Clear token from BaseApiService
    BaseApiService.clearAuthToken();

    print('🗑️ Auth data cleared');
  }

  /// Test backend connection
  Future<bool> testConnection() async {
    try {
      return await AuthApiService.testConnection();
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }
}
