import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_draw_ai/presentation/screens/auth/reset_password_screen.dart';
import 'package:nova_draw_ai/presentation/screens/auth/signin_screen.dart';
import 'package:nova_draw_ai/presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/welcome_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/drawing/drawing_categories_screen.dart';
import '../presentation/screens/drawing/drawings_screen.dart';
import '../presentation/screens/drawing/drawing_steps_screen.dart';
import '../presentation/screens/drawing/drawing_upload_screen.dart';
import '../presentation/screens/drawing/drawing_edit_options_screen.dart';
import '../presentation/screens/drawing/drawing_final_result_screen.dart';
import '../presentation/screens/drawing/drawing_story_screen.dart';
import '../services/auth_service.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: "/welcome",
  
  // Auth Guard - Redirect logic for authentication
  redirect: (BuildContext context, GoRouterState state) async {
    final isLoggedIn = await AuthService.isLoggedIn();
    final currentPath = state.uri.toString();
    
    // Define public routes (no authentication required)
    final publicRoutes = [
      '/welcome',
      '/signin',
      '/signup',
      '/resetpassword',
    ];
    
    // Check if current route is public
    final isPublicRoute = publicRoutes.any((route) => currentPath.startsWith(route));
    
    print('🔐 Auth Guard Check:');
    print('   Current path: $currentPath');
    print('   Is logged in: $isLoggedIn');
    print('   Is public route: $isPublicRoute');
    
    // If not logged in and trying to access protected route
    if (!isLoggedIn && !isPublicRoute) {
      print('   ❌ Access denied - Redirecting to signin');
      return '/signin';
    }
    
    // If logged in and trying to access auth routes (except welcome)
    if (isLoggedIn && (currentPath == '/signin' || currentPath == '/signup')) {
      print('   ✅ Already logged in - Redirecting to categories');
      return '/drawings/categories';
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
      path: "/drawings/:categoryId/:drawingId",
      builder: (BuildContext context, GoRouterState state) {
        final categoryId = state.pathParameters['categoryId']!;
        final drawingId = state.pathParameters['drawingId']!;
        return DrawingStepsScreen(categoryId: categoryId, drawingId: drawingId);
      },
    ),
    GoRoute(
      path: "/drawings/:categoryId/:drawingId/upload",
      builder: (BuildContext context, GoRouterState state) {
        final categoryId = state.pathParameters['categoryId']!;
        final drawingId = state.pathParameters['drawingId']!;
        return DrawingUploadScreen(
          categoryId: categoryId,
          drawingId: drawingId,
        );
      },
    ),
    GoRoute(
      path: "/drawings/:categoryId/:drawingId/edit-options",
      builder: (BuildContext context, GoRouterState state) {
        final categoryId = state.pathParameters['categoryId']!;
        final drawingId = state.pathParameters['drawingId']!;
        final uploadedImage = state.extra as File?;
        return DrawingEditOptionsScreen(
          categoryId: categoryId,
          drawingId: drawingId,
          uploadedImage: uploadedImage,
        );
      },
    ),
    GoRoute(
      path: "/drawings/:categoryId/:drawingId/result",
      builder: (BuildContext context, GoRouterState state) {
        final categoryId = state.pathParameters['categoryId']!;
        final drawingId = state.pathParameters['drawingId']!;
        final extra = state.extra as Map<String, dynamic>?;
        final uploadedImage = extra?['uploadedImage'] as File?;
        final editedImageBytes = extra?['editedImageBytes'];
        final selectedEditOption = extra?['selectedEditOption'];
        return DrawingFinalResultScreen(
          categoryId: categoryId,
          drawingId: drawingId,
          uploadedImage: uploadedImage,
          editedImageBytes: editedImageBytes,
          selectedEditOption: selectedEditOption,
        );
      },
    ),
    GoRoute(
      path: "/drawings/:categoryId/:drawingId/story",
      builder: (BuildContext context, GoRouterState state) {
        final categoryId = state.pathParameters['categoryId']!;
        final drawingId = state.pathParameters['drawingId']!;
        final drawingImage = state.extra; // Can be File or Uint8List
        return DrawingStoryScreen(
          categoryId: categoryId,
          drawingId: drawingId,
          drawingImage: drawingImage,
        );
      },
    ),
  ],
);
