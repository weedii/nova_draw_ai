import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_draw_ai/presentation/screens/auth/reset_password_screen.dart';
import 'package:nova_draw_ai/presentation/screens/auth/signin_screen.dart';
import 'package:nova_draw_ai/presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/welcome_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/drawing/drawing_categories_screen.dart';
import '../presentation/screens/drawing/drawings_screen.dart';
import '../presentation/screens/drawing/drawing_steps_screen.dart';
import '../presentation/screens/drawing/drawing_upload_screen.dart';
import '../presentation/screens/drawing/drawing_edit_options_screen.dart';
import '../presentation/screens/drawing/drawing_final_result_screen.dart';
import '../presentation/screens/drawing/drawing_story_screen.dart';
import '../providers/user_provider.dart';

// Create router as a function to access BuildContext
GoRouter createAppRouter(UserProvider userProvider) {
  return GoRouter(
    initialLocation: "/welcome",

    // Make router reactive to auth state changes
    refreshListenable: userProvider,

    // Auth Guard - Redirect logic for authentication
    redirect: (BuildContext context, GoRouterState state) {
      final authState = userProvider.state;
      final isAuthenticated = authState == AuthState.authenticated;
      final currentPath = state.uri.toString();

      // Define public routes (no authentication required)
      final publicRoutes = ['/welcome', '/signin', '/signup', '/resetpassword'];

      // Check if current route is public
      final isPublicRoute = publicRoutes.any(
        (route) => currentPath.startsWith(route),
      );

      print('🔐 Auth Guard Check:');
      print('   Current path: $currentPath');
      print('   Auth state: $authState');
      print('   Is authenticated: $isAuthenticated');
      print('   Is public route: $isPublicRoute');

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isPublicRoute) {
        print('   ❌ Access denied - Redirecting to signin');
        return '/signin';
      }

      // If authenticated and on any public route, redirect to home
      if (isAuthenticated && isPublicRoute) {
        print('   ✅ Already authenticated - Redirecting to home');
        return '/home';
      }

      print('   ✅ Access granted');
      return null; // No redirect needed
    },

    routes: <RouteBase>[
      // Welcome Route
      GoRoute(
        path: "/welcome",
        builder: (BuildContext context, GoRouterState state) {
          return const WelcomeScreen();
        },
      ),

      // Auth Routes
      GoRoute(
        path: "/signin",
        builder: (BuildContext context, GoRouterState state) {
          return const SignInScreen();
        },
      ),
      GoRoute(
        path: "/signup",
        builder: (BuildContext context, GoRouterState state) {
          return const SignUpScreen();
        },
      ),
      GoRoute(
        path: "/resetpassword",
        builder: (BuildContext context, GoRouterState state) {
          return const ResetPasswordScreen();
        },
      ),

      // Settings Route
      GoRoute(
        path: "/settings",
        builder: (BuildContext context, GoRouterState state) {
          return const SettingsScreen();
        },
      ),

      // Home Route (with bottom navigation)
      GoRoute(
        path: "/home",
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),

      // Drawing Routes
      GoRoute(
        path: "/drawings/categories",
        builder: (BuildContext context, GoRouterState state) {
          return const DrawingCategoriesScreen();
        },
      ),
      GoRoute(
        path: "/drawings/:categoryId",
        builder: (BuildContext context, GoRouterState state) {
          final categoryId = state.pathParameters['categoryId']!;
          return DrawingsScreen(categoryId: categoryId);
        },
      ),
      GoRoute(
        path: "/drawings/:category/:subject",
        builder: (BuildContext context, GoRouterState state) {
          final category = state.pathParameters['category']!;
          final subject = state.pathParameters['subject']!;
          return DrawingStepsScreen(category: category, subject: subject);
        },
      ),
      GoRoute(
        path: "/drawings/:category/:subject/upload",
        builder: (BuildContext context, GoRouterState state) {
          final category = state.pathParameters['category']!;
          final subject = state.pathParameters['subject']!;
          return DrawingUploadScreen(category: category, subject: subject);
        },
      ),
      GoRoute(
        path: "/drawings/:category/:subject/edit-options",
        builder: (BuildContext context, GoRouterState state) {
          final category = state.pathParameters['category']!;
          final subject = state.pathParameters['subject']!;

          // Handle both old format (File directly) and new format (Map with extras)
          File? uploadedImage;
          String? originalImageUrl;
          String? dbDrawingId;

          if (state.extra is Map<String, dynamic>) {
            final extra = state.extra as Map<String, dynamic>;
            uploadedImage = extra['uploadedImage'] as File?;
            originalImageUrl = extra['originalImageUrl'] as String?;
            dbDrawingId = extra['dbDrawingId'] as String?;
          } else if (state.extra is File) {
            uploadedImage = state.extra as File?;
          }

          return DrawingEditOptionsScreen(
            category: category,
            subject: subject,
            uploadedImage: uploadedImage,
            originalImageUrl: originalImageUrl,
            dbDrawingId: dbDrawingId,
          );
        },
      ),
      GoRoute(
        path: "/drawings/:category/:subject/result",
        builder: (BuildContext context, GoRouterState state) {
          final category = state.pathParameters['category']!;
          final subject = state.pathParameters['subject']!;
          final extra = state.extra as Map<String, dynamic>?;
          final originalImageUrl = extra?['originalImageUrl'] as String?;
          final editedImageUrl = extra?['editedImageUrl'] as String?;
          final selectedEditOption = extra?['selectedEditOption'];
          final dbDrawingId = extra?['drawing_id'] as String?;
          return DrawingFinalResultScreen(
            category: category,
            subject: subject,
            originalImageUrl: originalImageUrl,
            editedImageUrl: editedImageUrl,
            selectedEditOption: selectedEditOption,
            dbDrawingId: dbDrawingId,
          );
        },
      ),
      GoRoute(
        path: "/drawings/:categoryId/:drawingId/story",
        builder: (BuildContext context, GoRouterState state) {
          final categoryId = state.pathParameters['categoryId']!;
          final drawingId = state.pathParameters['drawingId']!;

          // Handle both old format (File/Uint8List directly) and new format (Map with extras)
          dynamic drawingImage;
          String? imageUrl;
          String? dbDrawingId;

          if (state.extra is Map<String, dynamic>) {
            final extra = state.extra as Map<String, dynamic>;
            drawingImage = extra['drawingImage'];
            imageUrl = extra['imageUrl'] as String?;
            dbDrawingId = extra['dbDrawingId'] as String?;
          } else {
            // Old format: extra is File or Uint8List directly
            drawingImage = state.extra;
          }

          return DrawingStoryScreen(
            categoryId: categoryId,
            drawingId: drawingId,
            drawingImage: drawingImage,
            imageUrl: imageUrl,
            dbDrawingId: dbDrawingId,
          );
        },
      ),

      // Direct Upload Result Route
      GoRoute(
        path: "/drawings/direct/upload/result",
        builder: (BuildContext context, GoRouterState state) {
          final extra = state.extra as Map<String, dynamic>?;
          final originalImageUrl = extra?['originalImageUrl'] as String?;
          final editedImageUrl = extra?['editedImageUrl'] as String?;
          final dbDrawingId = extra?['drawing_id'] as String?;
          return DrawingFinalResultScreen(
            category: 'direct',
            subject: 'upload',
            originalImageUrl: originalImageUrl,
            editedImageUrl: editedImageUrl,
            selectedEditOption: null,
            dbDrawingId: dbDrawingId,
          );
        },
      ),
    ],
  );
}
