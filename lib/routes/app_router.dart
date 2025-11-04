import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_draw_ai/presentation/screens/auth/reset_password_screen.dart';
import 'package:nova_draw_ai/presentation/screens/auth/signin_screen.dart';
import 'package:nova_draw_ai/presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/welcome_screen.dart';
import '../presentation/screens/drawing/drawing_categories_screen.dart';
import '../presentation/screens/drawing/drawings_screen.dart';
import '../presentation/screens/drawing/drawing_steps_screen.dart';
import '../presentation/screens/drawing/drawing_upload_screen.dart';
import '../presentation/screens/drawing/drawing_edit_result_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: "/welcome",
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
      path: "/drawings/:categoryId/:drawingId/edit-result",
      builder: (BuildContext context, GoRouterState state) {
        final categoryId = state.pathParameters['categoryId']!;
        final drawingId = state.pathParameters['drawingId']!;
        return DrawingEditResultScreen(
          categoryId: categoryId,
          drawingId: drawingId,
        );
      },
    ),
  ],
);
