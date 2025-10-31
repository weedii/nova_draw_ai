import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_draw_ai/presentation/screens/auth/reset_password_screen.dart';
import 'package:nova_draw_ai/presentation/screens/auth/signin_screen.dart';
import 'package:nova_draw_ai/presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/welcome_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: "/resetpassword",
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
  ],
);
